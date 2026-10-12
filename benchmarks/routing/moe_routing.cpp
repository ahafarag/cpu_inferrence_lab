// moe_routing: prefill a prompt and print which experts every token routes to, per MoE layer.
// Built as a llama.cpp example (see build_routing.sh). Output lines: "ROUTE <layer> <token_idx> e0 e1 ... e(k-1)".
// Routing of a token does not depend on batching, so prefilling real text gives the expert sequence a decode would see.
#include "arg.h"
#include "common.h"
#include "log.h"
#include "llama.h"
#include "ggml.h"
#include "ggml-backend.h"

#include <clocale>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>

static bool routing_cb(struct ggml_tensor * t, bool ask, void * /*user_data*/) {
    const bool is_topk = strncmp(t->name, "ffn_moe_topk", 12) == 0;
    if (ask) {
        return is_topk;                       // only ask the scheduler for the top-k selection tensors
    }
    if (!is_topk || t->type != GGML_TYPE_I32) {
        return true;
    }
    int layer = -1;
    const char * dash = strrchr(t->name, '-');
    if (dash) {
        layer = atoi(dash + 1);
    }
    const int64_t n_used = t->ne[0];
    const int64_t n_tok  = t->ne[1];
    std::vector<int32_t> row(n_used);
    for (int64_t i = 0; i < n_tok; ++i) {
        ggml_backend_tensor_get(t, row.data(), (size_t) i * t->nb[1], (size_t) n_used * sizeof(int32_t));
        printf("ROUTE %d %lld", layer, (long long) i);
        for (int64_t j = 0; j < n_used; ++j) {
            printf(" %d", row[j]);
        }
        printf("\n");
    }
    return true;
}

int main(int argc, char ** argv) {
    std::setlocale(LC_NUMERIC, "C");
    common_params params;
    common_init();
    if (!common_params_parse(argc, argv, params, LLAMA_EXAMPLE_COMMON)) {
        return 1;
    }
    llama_backend_init();
    llama_numa_init(params.numa);

    params.cb_eval           = routing_cb;
    params.cb_eval_user_data = nullptr;
    params.warmup            = false;

    auto llama_init = common_init_from_params(params);
    auto * model = llama_init->model();
    auto * ctx   = llama_init->context();
    if (model == nullptr || ctx == nullptr) {
        fprintf(stderr, "failed to init\n");
        return 1;
    }
    const llama_vocab * vocab = llama_model_get_vocab(model);
    const bool add_bos = llama_vocab_get_add_bos(vocab);
    std::vector<llama_token> tokens = common_tokenize(ctx, params.prompt, add_bos, true);
    if (tokens.empty()) {
        fprintf(stderr, "no tokens (use -p or -f)\n");
        return 1;
    }
    fprintf(stderr, "tokens=%zu\n", tokens.size());
    printf("TOKENS %zu\n", tokens.size());

    common_batch batch = common_batch_get_one(ctx, tokens);
    if (llama_process(ctx, LLAMA_PROCESS_TYPE_DECODE, batch.get())) {
        fprintf(stderr, "decode failed\n");
        return 1;
    }
    llama_backend_free();
    return 0;
}

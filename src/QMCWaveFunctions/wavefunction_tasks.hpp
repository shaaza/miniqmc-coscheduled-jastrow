//
// Created by Ahmed, Shaaz on 2019-09-08.
//

#ifndef QMCPLUSPLUS_WAVEFUNCTION_TASKS_HPP
#define QMCPLUSPLUS_WAVEFUNCTION_TASKS_H

struct ratio_grad_params {
    qmcplusplus::ParticleSet& P;
    int iat;
    qmcplusplus::TinyVector<OHMMS_PRECISION, OHMMS_DIM>& grad;
    std::vector<qmcplusplus::WaveFunctionComponent*>& WFs;
    size_t i;
};

void jastrow_cpu_func(void *buffers[], void *cl_arg) {
  struct ratio_grad_params *p = (ratio_grad_params *) cl_arg;
  OHMMS_PRECISION ratio = p->WFs[p->i]->ratioGrad(p->P, p->iat, p->grad);
  OHMMS_PRECISION *ratios = (OHMMS_PRECISION *) STARPU_VECTOR_GET_PTR(buffers[0]);
  ratios[p->i + 1] = ratio;
}

struct starpu_codelet jastrow_ratio_grad_codelet = []{
    struct starpu_codelet cl{};
    starpu_codelet_init(&jastrow_ratio_grad_codelet);
    cl.cpu_funcs[0] = jastrow_cpu_func;
    cl.nbuffers = 1;
    cl.modes[0] = STARPU_W;
    return cl;
}();

struct starpu_task *new_task(struct starpu_codelet *cl,
                             struct ratio_grad_params &args,
                             starpu_data_handle_t &handle) {
  struct starpu_task *task = starpu_task_create();
  task->cl = cl;
  task->handles[0] = handle;
  task->cl_arg = &args;
  task->cl_arg_size = sizeof(args);
  return task;
}

#endif // QMCPLUSPLUS_WAVEFUNCTION_TASKS_HPP
import Gen: @gen, mh, normal
import GenDirectionalStats: small_angle_random_axis_mh

include("scene.jl")
include("model.jl")


@gen function random_walk_proposal(trace, addr, width)
    prev_value = trace[addr]
    {addr} ~ normal(prev_value, width)
end

function random_walk_mh(trace, addr, width)
    return mh(trace, random_walk_proposal, (addr, width))
end

function pos_kernel(trace, get_addr; scale=1)
    for x in [:x, :y, :z]
        trace, = random_walk_mh(trace, get_addr(x), 0.1 * scale)
    end
    return trace
end

function orn_kernel(trace, get_addr; scale=1)
    trace, = small_angle_random_axis_mh(trace, get_addr(:rot), pi / 12 * scale)
    return trace
end

function pose_kernel(trace, get_addr; scale=1)
    trace = pos_kernel(trace, get_addr; scale=scale)
    trace = orn_kernel(trace, get_addr; scale=scale)
    return trace
end

function rejuvenation_kernel!(pf_state, t::Int; num_iters=500, verbose=false)
    traces = Gen.get_traces(pf_state)
    for (i, trace) in enumerate(traces)
        verbose && println("  Particle $i")
        for iter in 1:num_iters
            verbose && println("    Iter $iter")
            for i in 1:get_num_objects(trace)
                trace = pose_kernel(trace, x -> :gs => 1 => (:obj, i) => x; scale=num_iters/(10*iter))
            end
            trace = pos_kernel(trace, x -> :gs => t => :agent => x; scale=num_iters/(10*iter))
        end
        traces[i] = trace
    end
end

function do_smc(model, obs_gs::Vector{<:MetaDiGraph}, hypers::Hypers; num_particles::Int=1)
    # construct initial observation
    init_obs = Gen.choicemap()
    for (name, pose) in S.floatingPosesOf(obs_gs[1])
        init_obs[:gs => 1 => :obs => name] = pose
        init_obs[:gs => 1 => :agent => :rot] = S.IDENTITY_ORN  # TODO remove me
    end

    pf_state = Gen.initialize_particle_filter(model, (1,hypers), init_obs, num_particles)
    println("Filtering 1")
    rejuvenation_kernel!(pf_state, 1; num_iters=3000)

    for t in 2:length(obs_gs)
        # construct new observation
        new_obs = Gen.choicemap()
        for (name, pose) in S.floatingPosesOf(obs_gs[t])
            new_obs[:gs => t => :obs => name] = pose
            new_obs[:gs => t => :agent => :rot] = S.IDENTITY_ORN
        end
        println("Filtering $t")

        # extend particle filter to include observations at time t
        Gen.particle_filter_step!(pf_state, (t, hypers), (Gen.UnknownChange(), Gen.NoChange()), new_obs)
        rejuvenation_kernel!(pf_state, t; num_iters=30)
    end

    test_trace = Gen.get_traces(pf_state)[1]
    return Gen.get_retval(test_trace), Gen.get_score(test_trace)
end

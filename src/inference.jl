import Gen: @gen, mh, normal
import GenDirectionalStats: small_angle_random_axis_mh


@gen function random_walk_proposal(trace, addr, width)
    prev_value = trace[addr]
    {addr} ~ normal(prev_value, width)
end

function random_walk_mh(trace, addr, width)
    return mh(trace, random_walk_proposal, (addr, width))
end

function pos_kernel(trace, name; scale=1)
    trace, = random_walk_mh(trace, name => :x, 0.1 * scale)
    trace, = random_walk_mh(trace, name => :y, 0.1 * scale)
    trace, = random_walk_mh(trace, name => :z, 0.1 * scale)
    return trace
end

function orn_kernel(trace, name; scale=1)
    trace, = small_angle_random_axis_mh(trace, name => :rot, pi / 12 * scale)
    return trace
end

function pose_kernel(trace, name; scale=1)
    trace = pos_kernel(trace, name; scale=scale)
    trace = orn_kernel(trace, name; scale=scale)
    return trace
end

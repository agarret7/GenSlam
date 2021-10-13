import Gen: @gen, mh, normal
import GenDirectionalStats: small_angle_random_axis_mh


@gen function random_walk_proposal(trace, addr, width)
    prev_value = trace[addr]
    {addr} ~ normal(prev_value, width)
end

function random_walk_mh(trace, addr, width)
    return mh(trace, random_walk_proposal, (addr, width))
end

function pose_kernel(trace, name)
    metadata = Dict()
    trace, metadata[:accepted_x] = random_walk_mh(trace, name => :x, 0.1)
    trace, metadata[:accepted_y] = random_walk_mh(trace, name => :y, 0.1)
    trace, metadata[:accepted_z] = random_walk_mh(trace, name => :z, 0.1)
    trace, metadata[:accepted_rot] = small_angle_random_axis_mh(trace, name => :rot, pi / 12)
    return trace, metadata
end

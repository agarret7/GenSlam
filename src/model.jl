import Gen: @gen, Unfold, uniform
import Gen
import GenDirectionalStats: uniform_rot3
import GenSceneGraphs
import Parameters: @with_kw
import MetaGraphs: MetaDiGraph
S = GenSceneGraphs

include("gaussian_vmf.jl")


AGENT_SHAPE = S.Cylinder(0.1, 0.3)
TEST_BOX_SHAPE = S.Box(0.1, 0.1, 0.1)
Bounds = @NamedTuple{xmin::Real, xmax::Real, ymin::Real, ymax::Real, zmin::Real, zmax::Real}
get_num_objects(trace) = Gen.get_args(trace)[2].num_objects

@with_kw mutable struct Hypers
    # static params
    """Number of objects in the scene"""
    num_objects::Int
    """Bounds of the support for pose of floating objects in the initial scene
       state (uniformly distributed)"""
    scene_pose_bounds::Bounds

    # observation model params
    """Stdev of each individual coordinate of the (x,y,z) position of
       (non-flicker) detections; joint stdev is this times √3"""
    obs_pos_stdev::Real
    """Concentration of the orientation error for (non-flicker) detections (von
       Mises–Fisher distributed)"""
    obs_rot_conc::Real

    # dynamics params
    """Stdev of drift offset for each coordinate in (x,y,z) position of
       objects, within 1 unit time"""
    pos_drift_length::Union{Real,Nothing} = nothing
    rot_drift_conc::Union{Real,Nothing} = nothing
end


####################
### Static Model ###
####################

@gen function init_object_pose(hypers)::S.Pose
    bounds = hypers.scene_pose_bounds
    x ~ uniform(bounds.xmin, bounds.xmax)
    y ~ uniform(bounds.ymin, bounds.ymax)
    z ~ uniform(bounds.zmin, bounds.zmax)
    rot ~ uniform_rot3()
    return S.Pose(x, y, z, rot)
end

@gen function init_agent_pose(hypers)::S.Pose
    bounds = hypers.scene_pose_bounds
    x ~ uniform(bounds.xmin, bounds.xmax)
    y ~ uniform(bounds.ymin, bounds.ymax)
    z ~ uniform(bounds.zmin, bounds.zmax)
    rot ~ uniform_rot3()
    return S.Pose(x, y, z, rot)
end

@gen function obs_model(g::MetaDiGraph, hypers::Hypers)
    g = deepcopy(g)
    agent_pose = S.getAbsolutePose(g, :agent)
    S.removeObject!(g, :agent)
    observed_poses = S.Pose[]
    for (name, pose) in S.floatingPosesOf(g)
        rel_pose = pose / agent_pose
        observed_pose = {name} ~ gaussianVMF(rel_pose, hypers.obs_pos_stdev, hypers.obs_rot_conc)
        push!(observed_poses, observed_pose)
    end
    return observed_poses
end

@gen function static_model(hypers)
    agent_pose = {:agent} ~ init_agent_pose(hypers)
    g = S.SceneGraph()
    S.addObject!(g, :agent, AGENT_SHAPE)
    S.setPose!(g, :agent, agent_pose)
    for i in 1:hypers.num_objects
        pose = {(:obj, i)} ~ init_object_pose(hypers)
        S.addObject!(g, (:obj, i), TEST_BOX_SHAPE)
        S.setPose!(g, (:obj, i), pose)
    end
    {:obs} ~ obs_model(g, hypers)
    return g
end


#####################
### Dynamic Model ###
#####################

@gen function step_agent_forward(pose::S.Pose, hypers::Hypers)::S.Pose
    # TODO add velocity model, truncated normal
    x ~ normal(pose.pos[1], hypers.pos_drift_length)
    y ~ normal(pose.pos[2], hypers.pos_drift_length)
    z ~ normal(pose.pos[3], hypers.pos_drift_length)
    rot ~ vmf_rot3(pose.orientation, hypers.rot_drift_conc)
    return S.Pose(x, y, z, rot)
end

@gen function step_forward(
    t::Int,
    prev_g::Union{MetaDiGraph,Nothing},
    hypers::Hypers,
)
    if prev_g == nothing  ################################ initial time step
        g = S.SceneGraph()
        for i in 1:hypers.num_objects
            pose = {(:obj, i)} ~ init_object_pose(hypers)
            S.addObject!(g, (:obj, i), TEST_BOX_SHAPE)
            S.setPose!(g, (:obj, i), pose)
        end
        S.addObject!(g, :agent, AGENT_SHAPE)
        agent_pose = {:agent} ~ init_agent_pose(hypers)
    else  ################################################ step dynamics forward
        g = deepcopy(prev_g)
        agent_pose = {:agent} ~ step_agent_forward(S.getAbsolutePose(prev_g, :agent), hypers)
    end
    S.setPose!(g, :agent, agent_pose)
    {:obs} ~ obs_model(g, hypers)
    return g
end

steps = Gen.Unfold(step_forward)

@gen function model(num_time_steps::Int, hypers::Hypers)
    @assert !isnothing(hypers.pos_drift_length)
    @assert !isnothing(hypers.rot_drift_conc)
    gs ~ steps(num_time_steps, nothing, hypers)
    return MetaDiGraph[gs...]
end

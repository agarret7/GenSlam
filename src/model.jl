import Gen: @gen, Unfold, uniform
import Gen
import GenDirectionalStats: uniform_rot3
import GenSceneGraphs
import Parameters: @with_kw
import MetaGraphs: MetaDiGraph
S = GenSceneGraphs

include("gaussian_vmf.jl")


Bounds = @NamedTuple{xmin::Real, xmax::Real, ymin::Real, ymax::Real, zmin::Real, zmax::Real}

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
    agent_pose = agent ~ init_agent_pose(hypers)
    g = S.SceneGraph()
    S.addObject!(g, :agent, S.Box(0.01, 0.01, 0.01))
    S.setPose!(g, :agent, agent_pose)
    for i in 1:hypers.num_objects
        pose = {(:obj, i)} ~ init_object_pose(hypers)
        S.addObject!(g, (:obj, i), S.Box(0.2,0.2,0.2))
        S.setPose!(g, (:obj, i), pose)
    end
    {:obs} ~ obs_model(g, hypers)
    return g
end


#####################
### Dynamic Model ###
#####################

@gen function agent_trajectory(pose::S.Pose, hypers::Hypers)::S.Pose
    x ~ normal(pose.pos[1], hypers.floating_pos_drift_length)
    y ~ normal(pose.pos[2], hypers.floating_pos_drift_length)
    z ~ normal(pose.pos[3], hypers.floating_pos_drift_length)
    rot ~ vmf_rot3(pose.orientation, hypers.floating_rot_drift_conc)
    return S.Pose(x, y, z, rot)
end

@gen function step_forward(
    t::Int,
    prev_g::Union{MetaDiGraph,Nothing},
    hypers::Hypers,
)
end

steps = Gen.Unfold(step_forward)

@gen (static) function model(num_time_steps::Int, hypers)
    gs ~ steps(num_time_steps, nothing, hypers)
    return MetaDiGraph[gs...]
end

function sample_scene(num_objects::Int)
    # construct the agent
    agent_pose = S.Pose(0.5, -0.5, 0, S.IDENTITY_ORN)
    agent_camera = S.cameraConfigFromAngleAspect(
        cameraEyePose = agent_pose,
        fovDegrees = 42.5,
        aspect = 1,
        nearVal = 0.01,
        farVal = 100.0,
    )
    agent_view = S.ViewSpec(camera=agent_camera)

    # construct the scene
    g = S.SceneGraph()
    S.setSuggestedView!(g, agent_view)
    S.addObject!(g, :agent, S.Box(0.01, 0.01, 0.01))
    S.setPose!(g, :agent, agent_pose)
    for i in 1:num_objects
        x = uniform(0, 1)
        y = uniform(0, 1)
        pose = S.Pose(x, y, -0.1, S.IDENTITY_ORN)
        S.addObject!(g, (:obj, i), S.Box(0.1,0.1,0.1))
        S.setPose!(g, (:obj, i), pose)
    end
    return g, agent_view
end

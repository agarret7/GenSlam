import MetaGraphs: MetaDiGraph
import GenSceneGraphs
S = GenSceneGraphs


function gt_g_to_obs_g(gt_g::MetaDiGraph)
    obs_g = deepcopy(gt_g)
    agent_pose = S.getAbsolutePose(obs_g, :agent)
    S.removeObject!(obs_g, :agent)
    for (name, pose) in S.floatingPosesOf(obs_g)
        rel_pose = pose / agent_pose
        S.setPose!(obs_g, name, rel_pose)
    end
    return obs_g
end

function make_agent_view(agent_pose::S.Pose)
    agent_camera = S.cameraConfigFromAngleAspect(
        cameraEyePose = agent_pose,
        fovDegrees = 72.5,
        aspect = 1,
        nearVal = 0.01,
        farVal = 100.0,
    )
    agent_view = S.ViewSpec(camera=agent_camera)
    return agent_view
end

function sample_static_scene(num_objects::Int)
    # construct the agent
    agent_pose = S.Pose(0.5, -0.5, 0, S.IDENTITY_ORN)
    agent_view = make_agent_view(agent_pose)

    # construct the scene
    g = S.SceneGraph()
    S.setSuggestedView!(g, agent_view)
    S.addObject!(g, :agent, AGENT_SHAPE)
    S.setPose!(g, :agent, agent_pose)
    for i in 1:num_objects
        x = uniform(0, 1)
        y = uniform(0, 1)
        pose = S.Pose(x, y, -0.1, S.IDENTITY_ORN)
        S.addObject!(g, (:obj, i), TEST_BOX_SHAPE)
        S.setPose!(g, (:obj, i), pose)
    end
    return g, agent_view
end

function get_agent_trajectory(t::Int; period::Int=20)
    x = 0.4*cos(t * 2*pi/period)
    y = -0.5 + 0.4*sin(t * 2*pi/period)
    return S.Pose(x, y, 0, S.IDENTITY_ORN)
end

function sample_dynamic_scene(num_objects::Int, num_time_steps::Int)
    # construct the agent
    agent_pose = get_agent_trajectory(0)

    # construct the scene
    init_g = S.SceneGraph()
    for i in 1:num_objects
        x = uniform(0, 1)
        y = uniform(0, 1)
        pose = S.Pose(x, y, -0.1, S.IDENTITY_ORN)
        S.addObject!(init_g, (:obj, i), TEST_BOX_SHAPE)
        S.setPose!(init_g, (:obj, i), pose)
    end
    S.addObject!(init_g, :agent, AGENT_SHAPE)
    S.setPose!(init_g, :agent, agent_pose)

    gs = MetaDiGraph[init_g]
    agent_views = S.ViewSpec[]
    for t in 1:num_time_steps-1
        g = deepcopy(init_g)
        agent_pose = get_agent_trajectory(t)
        S.setPose!(g, :agent, agent_pose)
        push!(gs, g)
        agent_view = make_agent_view(agent_pose)
        push!(agent_views, agent_view)
    end
    return gs, agent_views
end

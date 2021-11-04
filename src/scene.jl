import PoseComposition: Pose, IDENTITY_ORN


function gt_poses_to_obs_poses(gt_poses::Vector{Pose})
    obs_poses = deepcopy(gt_poses)
    agent_pose = pop!(obs_poses)
    for (i, pose) in enumerate(obs_poses)
        name = (:obj, i)
        rel_pose = pose / agent_pose
        obs_poses[i] = rel_pose
    end
    return obs_poses
end

function sample_static_scene(num_objects::Int)
    # construct the agent
    agent_pose = Pose(0.5, -0.5, 0, IDENTITY_ORN)

    # construct the scene
    poses = Pose[]
    for i in 1:num_objects
        x = uniform(0, 1)
        y = uniform(0, 1)
        pose = Pose(x, y, -0.1, IDENTITY_ORN)
        push!(poses, pose)
    end
    push!(poses, agent_pose)
    return poses
end

function get_agent_trajectory(t::Int; period::Int=20)
    x = 0.4*cos(t * 2*pi/period)
    y = -0.5 + 0.4*sin(t * 2*pi/period)
    return Pose(x, y, 0, IDENTITY_ORN)
end

function sample_dynamic_scene(num_objects::Int, num_time_steps::Int)
    # construct the scene
    init_poses = Pose[]
    for i in 1:num_objects
        x = uniform(0, 1)
        y = uniform(0, 1)
        pose = Pose(x, y, -0.1, IDENTITY_ORN)
        push!(init_poses, pose)
    end

    # construct the agent
    agent_pose = get_agent_trajectory(0)
    push!(init_poses, agent_pose)

    # simulate the agent's trajectory
    all_poses = Vector{Pose}[init_poses]
    for t in 1:num_time_steps-1
        poses = deepcopy(init_poses)
        agent_pose = get_agent_trajectory(t)
        poses[end] = agent_pose
        push!(all_poses, poses)
    end

    return all_poses
end

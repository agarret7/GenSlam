import Gen: @gen
import Gen
import GenSceneGraph

@gen function motion_model()
end

@gen function obs_model()
end

@gen function model(T::int)
    agent_pose = ({:init_pose, 1}) init_agent_pose()
    (agent_poses, observations) ~ dynamics(agent_pose, T)
    [agent_pose, agent_poses...]
end


function sample_scene(N::Int)
    poses = Pose[]
    for _ in 1:N
        x = uniform()
        y = uniform()
        Pose(x, y, 1., )
        x, y
        push!(poses, pose)
    end
    poses
end

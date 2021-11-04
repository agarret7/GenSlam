import Gen
import PoseComposition: Pose
import Base64: base64encode
using PyPlot


get_x(pose::Pose) = pose.pos[1]
get_y(pose::Pose) = pose.pos[2]

function plot_topdown_view(poses::Vector{Pose})
    poses = deepcopy(poses)

    fig, ax = subplots(figsize=(5, 5))
    ax.set_xlim(-1, 1)
    ax.set_ylim(-1, 1)

    agent_pose = pop!(poses)
    ax.scatter(get_x.(poses), get_y.(poses))
    ax.scatter(get_x(agent_pose), get_y(agent_pose), c="red")
end

function _showanim(filename)
    open(filename) do f
        base64_video = base64encode(f)
        display("text/html", """<video controls src="data:video/x-m4v;base64,$base64_video">""")
    end
end

function animate_topdown_view(all_poses::Vector{<:AbstractVector{Pose}})
    all_poses = deepcopy(all_poses)

    # create plot
    fig, ax = subplots(figsize=(5, 5))
    ax.set_xlim(-1, 1)
    ax.set_ylim(-1, 1)

    # create animation objects
    obj_markers = ax.scatter([], [])
    agent_marker = ax.scatter([], [], c="r")

    function init()
        return (obj_markers, agent_marker)
    end

    function animate(i)
        t = i + 1
        agent_pose = pop!(all_poses[t])
        obj_markers.set_offsets(collect(zip(get_x.(all_poses[t]), get_y.(all_poses[t]))))
        agent_marker.set_offsets([get_x(agent_pose), get_y(agent_pose)])
        return (obj_markers, agent_marker)
    end

    withfig(fig, clear=false) do
        anim = animation().FuncAnimation(fig, animate, init_func=init, frames=length(all_poses), interval=500)
        anim.save("/tmp/anim.mp4", bitrate=-1, extra_args=["-vcodec", "libx264", "-pix_fmt", "yuv420p"])
        _showanim("/tmp/anim.mp4")
    end
end

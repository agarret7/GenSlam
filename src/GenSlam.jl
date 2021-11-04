module GenSlam

import PyCall: pyimport
import Memoize: @memoize

include("gaussian_vmf.jl")
include("scene.jl")
include("model.jl")
include("inference.jl")
include("visualization.jl")

@memoize animation() = pyimport("matplotlib.animation")

export sample_static_scene,
       sample_dynamic_scene,
       gt_poses_to_obs_poses,
       make_agent_view,
       Hypers,
       Bounds,
       static_model,
       model,
       pos_kernel,
       orn_kernel,
       pose_kernel,
       do_smc,
       plot_topdown_view,
       animate_topdown_view

end # module

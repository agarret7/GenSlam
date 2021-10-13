module GenSlam

import Gen
import Random
import GenSceneGraphs
import PyPlot
import Images
import FileIO: save
S = GenSceneGraphs

Random.seed!(0)

include("model.jl")

num_objects = 3
g, agent_view = sample_scene(num_objects)
agent_pose = S.getAbsolutePose(g, :agent)
S.removeObject!(g, :agent)
# rgba, = S.renderScene(g; view=agent_view)
# @show size(rgba)
# save("test.png", rgba)

# generate initial state
hypers = Hypers(
    num_objects = 3,
    scene_pose_bounds = (xmin=-1,xmax=1,ymin=-1,ymax=1,zmin=-0.2,zmax=0.2),
    obs_pos_stdev = 0.05,
    obs_rot_conc = 500.
)
observations = Gen.choicemap()
for (name, pose) in S.floatingPosesOf(g)
    rel_pose = pose / agent_pose
    observations[:obs => name] = rel_pose
end
display(observations)
trace, weight = Gen.generate(static_model, (hypers,), observations)

# perform inference
include("inference.jl")

display(trace[:agent])
for iter in 1:5000
    global trace
    trace, metadata = pose_kernel(trace, (:obj, 1))
    trace, metadata = pose_kernel(trace, (:obj, 2))
    trace, metadata = pose_kernel(trace, (:obj, 3))
    trace, metadata = pose_kernel(trace, :agent)
    @show iter, Gen.get_score(trace)
end
display(trace[:agent])

end # module

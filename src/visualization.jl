import Gen
import GenSceneGraphs
S = GenSceneGraphs


TOPDOWN_VIEW = S.ViewSpec(camera=S.cameraConfigFromAngleAspect(
    cameraEyePose = S.Pose(0, 0, 5, (yaw=0,pitch=0,roll=-pi/2)),
    fovDegrees = 42.5,
    aspect = 4/3,
    nearVal = 0.01,
    farVal = 100.0,
))

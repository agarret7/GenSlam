import GenSceneGraphs
import Gen
import GenDirectionalStats: vmf_rot3, Rot3
S = GenSceneGraphs


struct GaussianVMF <: Gen.Distribution{S.Pose} end
const gaussianVMF = GaussianVMF()
function Gen.random(
    ::GaussianVMF,
    center::S.Pose,
    positionStdev::Real,
    orientationKappa::Real,
)::S.Pose
    rot = Gen.random(vmf_rot3, Rot3(1.0, 0.0, 0.0, 0.0), orientationKappa)
    offset = S.Pose(
        [
            Gen.normal(0, positionStdev),
            Gen.normal(0, positionStdev),
            Gen.normal(0, positionStdev),
        ],
        rot,
    )
    return S.:(⊗)(center, offset)
end
function Gen.logpdf(
    ::GaussianVMF,
    val::S.Pose,
    center::S.Pose,
    positionStdev::Real,
    orientationKappa::Real,
)
    offset = S.:(⦸)(center, val)
    return +(
        Gen.logpdf(Gen.normal, offset.pos[1], 0, positionStdev),
        Gen.logpdf(Gen.normal, offset.pos[2], 0, positionStdev),
        Gen.logpdf(Gen.normal, offset.pos[3], 0, positionStdev),
        Gen.logpdf(
            vmf_rot3,
            Rot3(offset.orientation),
            Rot3(1.0, 0.0, 0.0, 0.0),
            orientationKappa,
        ),
    )
end
Gen.has_output_grad(::GaussianVMF) = false
Gen.has_argument_grads(::GaussianVMF) = (false, false, false)
function Gen.logpdf_grad(
    ::GaussianVMF,
    center::S.Pose,
    positionStdev::Real,
    orientationKappa::Real,
)
    return (nothing, nothing, nothing, nothing)
end

export gaussianVMF

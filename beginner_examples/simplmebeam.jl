# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/JuliaFEM.jl/blob/master/LICENSE.md

# # Natural frequency analysis of a formula frame

# The model is a 3d formula frame shown in picture. Geometry is from Formula
# Studen Oulu. Material and cross-section values used in this example
# aren't the same ones used in the real frame. Boundary conditions may also
# differ from the analysis done by Formula Student Oulu.

# ![](f_frame/model.png)

using JuliaFEM
using FEMBase.Test
using Logging
Logging.configure(level=INFO)
add_elements! = JuliaFEM.add_elements!

# Creating geometry.

L1 = 270; L2 = 150; L3 = 400; H = 530 # [mm]

X = Dict(1 => [ 0.0,  0.0,  0.0],
         2 => [L1+L2, 0.0,  0.0],
         3 => [L1,    H,    0.0],
         4 => [L1+L2+L3, H, 0.0])

# Creating five beam elements

beam1 = Element(Seg2, [1,2])
beam2 = Element(Seg2, [1,3])
beam3 = Element(Seg2, [2,3])
beam4 = Element(Seg2, [3,5])
beam5 = Element(Seg2, [2,5])

beam_elements = [beam1, beam2, beam3, beam4, beam5]
info("Number of elements: ", length(beam_elements))

# Defining material values for beam elements. In this case structural streel
# values are used.
update!(beam_elements, "geometry", X)
update!(beam_elements, "youngs modulus", 210.0e3)
update!(beam_elements, "shear modulus", 80.77e3)
update!(beam_elements, "density", 7.800e-9)

# Defining cross-section values. We have to define cross-section area,
# moment of inertias in both local directions and polar moment of inertia.
# In this case values for 25mm x 2.5 circular tube (pipe) are used.

# To calculate inertias see:
# https://calcresource.com/moment-of-inertia-ctube.html
# For more information about moment of inertias:
# https://en.wikipedia.org/wiki/List_of_second_moments_of_area

update!(beam_elements, "cross-section area", 176.715)
update!(beam_elements, "torsional moment of inertia 1", 11320.778)
update!(beam_elements, "torsional moment of inertia 2", 11320.778)
update!(beam_elements, "polar moment of inertia", 22641.556)

# The direction of beam is defined in the same way as in ABAQUS.
# That is, we have a tangent direction and one normal direction.
# The third direction is then cross product of tangent and normal.
# This is a little shortcut to define all the beam orientations with one for
# loop. Because all the elements are pipes, we only need to define a vector
# which is orthogonal to tangent of the beam. This for loop finds the right
# vector for every beam element.

update!(beam_elements, "normal", [0.0, 0.0, -1.0])


# Create boundary conditions: fix all degrees of freedom for nodes in
# a set FIXED. Here we first create elements of type `Poi1` for each
# node j in set FIXED, update geometry field and then create new fields
# `fixed displacmeent 1`, `fixed displacement 2`, and so on, where the
# displacement / rotation is prescribed.



# Create a problem, containing beam elements and boundary conditions:

frame = Problem(Beam, "3d frame", 6)
add_elements!(frame, beam_elements)
add_elements!(frame, bc_elements)

# Perform modal analysis

step = Analysis(Modal)
step.properties.nev = 10
xdmf = Xdmf(joinpath(datadir, "f_frame_results"); overwrite=true)
add_results_writer!(step, xdmf)
add_problems!(step, [frame])
run!(step)
close(xdmf.hdf)

# Each `Analysis` can have properties, e.g. time, maximum number of iterations,
# convergence tolerance and so on. Eigenvalues of calculation are stored as a
# properties of analysis:

eigvals = step.properties.eigvals
freqs = sqrt(eigvals)/(2*pi)

println("Five lowest natural frequencies [Hz]:")
println(round.(freqs[1:5], 2))

# [![mode5](3d_frame/natfreq.png)](https://www.youtube.com/watch?v=GzktCqeASmo)

"""
Draw the Mandelbrot set in Julia with interactive zoom functionality.

License: CC0 1.0 Universal (Public Domain)
https://creativecommons.org/publicdomain/zero/1.0/

Assembled by John R. Frank in 2024 with help from ChatGPT.
"""

module MandelbrotZoom

using GLMakie, GeometryBasics, Printf

# put the new window on top
GLMakie.activate!(focus_on_show=true)

# specific aspect ratio for our view of the Mandelbrot set
const nice_aspect_ratio = 3.0 / 2.2

# This is a high enough resolution that it looks good on my screen...
const good_resolution = 2000

# Create a Figure window and draw an Axis in it
fig = Figure()
const ax = Axis(
    fig[1, 1], title = "Mandelbrot Set",
    aspect = nice_aspect_ratio,
    xlabel = "Real", ylabel = "Imaginary",

    # Rotate x and y tick labels by 45 degrees
    xticklabelrotation = π / 4,
    yticklabelrotation = π / 4
)

# Given a zoom rectangle `rect`, create linear ranges for x and y that
# maintain `aspect_ratio`
function rectangle_covering(
    rect::HyperRectangle;
    aspect_ratio::Float64 = nice_aspect_ratio,
    resolution::Integer = good_resolution)
    
    # Extract the original corner and dimensions
    x_min, y_min = rect.origin[1], rect.origin[2]
    width, height = rect.widths[1], rect.widths[2]
    
    # Calculate the current aspect ratio
    current_aspect = width / height
    
    # Adjust width or height to meet minimum aspect ratio
    if current_aspect < aspect_ratio
        # Increase width to match aspect ratio
        new_width = aspect_ratio * height
        new_height = height
    elseif current_aspect > aspect_ratio
        # Increase height to match aspect ratio A
        new_width = width
        new_height = width / aspect_ratio
    else
        # aspect ratio already met
        new_width, new_height = width, height
    end

    x_range = LinRange(x_min, x_min + new_width,  resolution)
    y_range = LinRange(y_min, y_min + new_height, resolution)
    return x_range, y_range

end

# Mandelbrot's famous "escape" function, used to generate `matrix`
function mandelbrot(x, y, detail)
    z = c = x + y * im
    for i in 1:detail  # Increase iterations for more detail
        abs(z) > 2 && return i
        z = z^2 + c
    end
    return 0
end

# plot subset of the Mandelbrot set within `rect` and adjust axis
function draw_mandelbrot(rect; resolution = good_resolution)        
    # Maintain fixed aspect ratio and `resolution`
    x_range, y_range = rectangle_covering(rect, resolution=resolution)

    # Grow `detail` exponentially as zoom increases
    base_detail = 500
    dx = x_range[end] - x_range[1]
    dy = y_range[end] - y_range[1]

    # Set minimum and maximum detail levels
    min_detail = 100
    max_detail = 5000

    detail = Int(clamp(round(max(
        base_detail * abs(log(dx)),
        base_detail * abs(log(dy))
    )), min_detail, max_detail))

    # adjust the axis to the new rectangle
    global ax
    xlims!(ax, x_range[1], x_range[end])
    ylims!(ax, y_range[1], y_range[end])

    # Do the expensive calculation
    matrix = mandelbrot.(x_range, y_range', detail)
    
    # Apply log transformation for contrast enhancement
    log_matrix = log.(matrix .+ 1)

    # Get the transformed range and set colorrange
    min_val, max_val = extrema(log_matrix)
    color_range = (min_val, max_val)
    
    # Choose a colormap and improve contrast
    cmap = :inferno  # Use a high-contrast colormap

    # plot the data
    heatmap!(
        ax, x_range, y_range, log_matrix,

        # Adjust `colorrange` to fit detail
        colormap=cmap, colorrange=color_range
    )

end

# set a start rectangle
const start_rect = HyperRectangle(-2, -1.1, 3, 2.2)

# add a button for going back to the initial picture
goback = Button(fig[2,1]; label = "Reset Zoom", tellwidth = false)
on(goback.clicks) do clicks
    draw_mandelbrot(start_rect)
end

# now enable zooming, thank you:
# https://docs.makie.org/dev/explanations/observables#Observables
Makie.deactivate_interaction!(ax, :rectanglezoom)
srect = select_rectangle(ax.scene)
on(srect) do rect
    # recraw within the new `rect`
    draw_mandelbrot(rect)
end


function julia_main()::Cint
    try

        println("Draw the famous picture.")
        draw_mandelbrot(start_rect)

        println("Wait for the display to be done...") 
        wait(display(fig))  # PackageCompiler --> segfault 11 on MacOS :-(
        
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end

# Check if this script is run directly from the command line
if abspath(PROGRAM_FILE) == @__FILE__
    println("called from command line")
    julia_main()
end

end # module

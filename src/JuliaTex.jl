module JuliaTeX

using Formatting
using StatsFuns

export texifycols, textable

const siglev_def = [0.05, 0.01, 0.001]
const dsgn = "\$"
const RealOrVec = Union{T,AbstractVector{T}} where {T<:Real}

function nstars(p::Real, siglev::Vector{<:Real}=siglev_def)
    0.0 <= p <= 1.0 || throw(DomainError("p must be in [0,1]"))
    return "^{" * (rpad("*"^sum(p .< siglev), length(siglev))) * "}"
end

fmt_xstar(x::Real, p::Real, d::Integer, siglev::Vector{<:Real}=siglev_def) = format("{:> 9.$(d)f}", x) * dsgn * nstars(p, siglev) * dsgn
fmt_xstar(x::AbstractVector, p::AbstractVector, d::Integer, siglev::Vector{<:Real}=siglev_def) = [fmt_xstar(xx, pp, d, siglev) for (xx,pp) in zip(x,p)]
padstrvec(x::Vector{String}) = rpad.(x, maximum(length.(x)))


function texifycols(x::RealOrVec, se::RealOrVec, t::RealOrVec, p::RealOrVec; dx::Integer=3, dse::Integer=3, dt::Integer=2, dp::Integer=2, siglev::Vector{<:Real}=siglev_def)
    length(t) == length(p) == length(x) == length(se) || throw(DimensionMismatch())

    strx = padstrvec( fmt_xstar(x, p, dx, siglev) )
    strse = padstrvec( format.("({:.$(dse)f})", se) )
    strt  = padstrvec( format.("{: .$(dt)f}", t)     )
    strp  = padstrvec( format.("{:.$(dp)f}", p)     )

    return (strx, strse, strt, strp)
end

function texifycols(x::RealOrVec, se::RealOrVec; kwargs...)
    length(x) == length(se) || throw(DimensionMismatch())
    t = x ./ se
    p = 2*normcdf.(-abs.(t))
    return texifycols(x, se, t, p; kwargs...)
end

function textable(strcols::NTuple{4,Vector{String}}, nms::Vector{String}=[""]; caption="Caption", label="label", note="")
    strx, strse, strt, strp = strcols
    if length(nms) != length(strx)
        strnms = padstrvec(["\$ \\theta_{$i} \$" for i in 1:length(strx)])
    elseif length(nms) == length(strx)
        strnms = padstrvec(nms)
    else
        throw(DimensionMismatch())
    end
    tbl = strnms .* " & " .* strx .* " & " .* strse .* " & " .* strt .* " & " .* strp .* " \\\\"

    str1 =[
        "%!TEX root = ./paper2.tex\n",
        "\\begin{table}[ht]",
            "\t\\centering",
            "\t\\caption{$caption}",
            "\t\\label{$label}",
            "\\begin{adjustbox}{max size={.95\\textwidth}{.45\\textheight}}",
            "\t\\begin{tabular}{lcccc}",
            "\t\tParameter & Estimate & SE & \$t\$-statistic & \$p\$-value \\\\",
            "\t\t\\midrule",
        ]
    str2 = "\t\t" .* tbl
    str3 = [
            "\t\t\\midrule",
            "\t\t\\multicolumn{5}{l}{\\scriptsize{\$^{***}p<0.001\$, \$^{**}p<0.01\$, \$^*p<0.05\$}} \\\\",
            length(note) > 0 ? "\t\t\\multicolumn{5}{l}{\\scriptsize $note} \\\\" : "",
            "\t\\end{tabular}",
            "\t\\end{adjustbox}",
        "\\end{table}",
    ]

    strout = join(vcat(str1,str2,str3), "\n")
end


# module end
end

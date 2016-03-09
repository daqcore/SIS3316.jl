# This file is a part of jl, licensed under the MIT License (MIT).

export sortevents!, sortevents


sortevents!(sorted::SortedEvents, unsorted::UnsortedEvents; merge_window = 10) = begin
    iterv(p::Pair{Int, Vector{RawChEvent}}) = Pair(p.first, IterView(p.second))
    getts(elem::Pair{Int, RawChEvent}) = elem.second.timestamp

    const input = Dict{Int, IterView{Vector{RawChEvent},Int}}(map(iterv, unsorted))
    const current = Vector{Pair{Int, RawChEvent}}()
    const pending = Vector{Pair{Int, RawChEvent}}()

    for (ch, events) in input
        if !isempty(events)
            push!(current, Pair(ch, shift!(events)))
        end
    end

    const merged = Dict{Int, RawChEvent}()
    while !isempty(current)
        sort!(current, by = getts)
        const reftime = current[1].second.timestamp

        empty!(merged)
        local n = 0
        while (n == 0) || !isempty(current) && (first(current).second.timestamp - reftime <= merge_window)
            const ch, event = shift!(current)
            merged[ch] = event
            !isempty(input[ch]) && push!(pending, Pair(ch, shift!(input[ch])))
            n += 1
        end
        while !isempty(pending) unshift!(current, pop!(pending)) end
        const mc = copy(merged)
        push!(sorted, mc)
    end

    sorted
end


sortevents(unsorted::UnsortedEvents; merge_window = 10) =
    sortevents!(SortedEvents(), unsorted, merge_window = merge_window)
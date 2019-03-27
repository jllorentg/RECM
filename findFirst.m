function [equipos] = findFirst(pc, thr)
pc_thr_a = pc < thr;
for i =1:length(pc_thr_a)
    if pc_thr_a(i) == 1
        equipos = i;
        break;
    end
end
end


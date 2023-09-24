#!/usr/bin/env python3

# pass the preview output file as the first argument
# it just picks the projection value out of each population which
# has the highest number of segregating sites.
# (following the recommendation on the easySFS website (and cited paper))


import sys


if len(sys.argv) < 2:
    sys.stder.write("pass projections output file as first arg")
    sys.exit(1)

projections = sys.argv[1]
pop = "invalid"

pop_order = []
best_proj = {}

with open(projections) as fd:
    for line in fd:
        line = line.strip()
        if not line:
            continue
        if line.startswith("#"):
            print(line)
        if line.startswith("("):
            pop_order += [pop]
            best_proj[pop] = (-1, -1)
            data = line.split("\t")
            for tup in data:
                point = tup.replace(")", "").replace("(", "").replace(",", "").split()
                point_n = (int(point[0], 10), int(point[1], 10))
                cur_max = best_proj[pop]
                if point_n[1] > cur_max[1]:
                    best_proj[pop] = point_n 
        else:
            pop = line

list_arg = []
for pop in pop_order:
    list_arg += [str(best_proj[pop][0])]
    print("pop %s value %s" % (pop, best_proj[pop]))

print("")
print("when using easySFS, pass:")
print("  `--proj=%s`" % (",".join(list_arg),))

import sys


def find_best_pair(d):
    s = 0
    e = 1
    best_sum = 0
    final = len(d) - 1

    while e <= final:
        this_s = d[s]
        this_e = d[e]
        if e < final and this_e > this_s:
            s = e
            this_s = d[s]
            this_e = d[s + 1]
        
        local_sum = int(this_s + this_e)
        if local_sum > best_sum:
            best_sum = local_sum
            
        e += 1

    return best_sum


def best_brute(d):
    s = 0
    best = 0
    while s < len(d) - 1:
        e = s + 1
        while e < len(d):
            total = int(d[s] + d[e])
            if total > best:
                best = total
            e += 1
        s += 1

    return best


if __name__ == '__main__':    
    data = []
    with open(sys.argv[1]) as f:
        for line in f:
            data.append(line.strip())

    s = 0
    for d in data:
        s += find_best_pair(d)

    print(s)


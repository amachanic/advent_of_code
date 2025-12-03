import sys


def _concat(d, s):
    o = ''
    for x in s:
        o += d[x]

    return o


def find_best_n(d, num):
    s = list(range(num))
    e = 1
    best_sum = 0

    while e < len(d):
        for s_pos, s_val in enumerate(s):
            if s_val >= e:
                break
            # If there are only enough digits left to fill a certain number of slots,
            # we have to move forward before we can check the value
            if (num - s_pos) > (len(d) - e):
                continue
            # If the current value is bigger than the set slot value, flip this and
            # all forward slots to the new one
            if d[s_val] < d[e]:
                for n_pos, n in enumerate(range(s_pos, num)):
                    s[n] = e + n_pos
                break

        local_sum = int(_concat(d, s))
        if local_sum > best_sum:
            best_sum = local_sum

        e += 1

    return best_sum


if __name__ == '__main__':    
    data = []
    with open(sys.argv[1]) as f:
        for line in f:
            data.append(line.strip())

    s = 0
    for d in data:
        s += find_best_n(d, 12)

    print(s)


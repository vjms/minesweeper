import random


def addmine(mf,  pos):
    if mf[pos] == -1:
        addmine(mf, (pos + random.randint(0, len(mf))) % len(mf))
    else:
        mf[pos] = -1


def is_mine(mf, index):
    return mf[index] == -1


def increase_neighbouring_mine_count(mf, rows, columns, row, column):
    if row < 0 or row >= rows:
        return
    if column < 0 or column >= columns:
        return
    try:
        index = row * columns + column
        if is_mine(mf, index):
            return
        mf[index] += 1
    except IndexError:
        ...


def get_location(index,  cols):
    return (index // cols, index % cols)


def gen_neighbours(mf, rows, cols):
    for i in range(len(mf)):
        if not is_mine(mf, i):
            continue
        row, col = get_location(i, cols)
        print(i, row, col)
        # left
        increase_neighbouring_mine_count(mf, rows, cols, row, col - 1)
        # right
        increase_neighbouring_mine_count(mf, rows, cols, row, col + 1)
        # up
        increase_neighbouring_mine_count(mf, rows, cols, row - 1, col)
        # up-left
        increase_neighbouring_mine_count(mf, rows, cols, row - 1, col - 1)
        # up-right
        increase_neighbouring_mine_count(mf, rows, cols, row - 1, col + 1)
        # down
        increase_neighbouring_mine_count(mf, rows, cols, row + 1, col)
        # down-left
        increase_neighbouring_mine_count(mf, rows, cols, row + 1, col - 1)
        # down-right
        increase_neighbouring_mine_count(mf, rows, cols, row + 1, col + 1)


rows = 10
cols = 10
mines = 10
minefield = [0] * (rows * cols)

for _ in range(0, mines):
    addmine(minefield,  random.randint(0, len(minefield) - 1))


gen_neighbours(minefield, rows, cols)

for row in range(rows):
    for col in range(cols):
        print(f'{minefield[row * cols + col]:2}', end=",")
    print("")

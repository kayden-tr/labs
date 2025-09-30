fib_list = [0, 1]

def fibonacci(n):
    if n <= 0:
        return 0
    elif n < len(fib_list):
        return fib_list[n]
    else:
        fib = fibonacci(n - 1) + fibonacci(n - 2)
        fib_list.append(fib)
        return fib
print(fibonacci(9))
print(fib_list)

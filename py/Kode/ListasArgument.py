def prime_numbers(num_list):
    primes = []
    for num in num_list:
        if num <= 1:
            continue  # bỏ qua số <= 1
        is_prime = True
        for i in range(2, int(num ** 0.5) + 1):  # chỉ cần kiểm tra đến căn bậc 2
            if num % i == 0:
                is_prime = False
                break
        if is_prime:
            primes.append(num)
    return primes

input_list = input*("Enter a list of numbers separated by spaces: ").split()
numbers = [int(x) for x in input_list]
print("Prime numbers list:", prime_numbers(numbers))

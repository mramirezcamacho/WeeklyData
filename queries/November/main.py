# Open the file in read mode
ids = []
with open('queries/November/shops_ids.txt', 'r') as file:
    # Read each line in the file
    for line in file:
        # Print each line, stripping any extra whitespace
        ids.append('"'+line.strip().replace('_', '')+'"')
# Open a new file in write mode
with open('queries/November/shops_ids_3_specificBDCarlosLozano.txt', 'w') as file:
    # Write a line of text to the file
    file.write("shop_id in\n")
    file.write("(\n")
    # You can add more lines as needed

    file.write(", \n".join(ids))
    file.write(")\n")

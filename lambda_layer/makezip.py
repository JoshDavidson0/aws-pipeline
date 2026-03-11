import zipfile, os
z = zipfile.ZipFile('/output/psycopg2-312.zip', 'w')
for r, d, files in os.walk('python'):
    for f in files:
        z.write(os.path.join(r, f))
z.close()
print('Done')

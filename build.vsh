println('Removing old artifacts...')
rmdir_all('bin') ?
println('Done removing "bin" directory.')

println('\nCreating new output directory "bin"...')
mkdir('bin') ?
println('Done creating "bin" directory.')

println('\nCompiling and building executable...')
execute_or_panic('v -prod . -o bin/klonol')
println('Done compiling and placing executable in "bin".')

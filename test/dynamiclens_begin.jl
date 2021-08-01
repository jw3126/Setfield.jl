l = @lens _[begin]
@test l isa Setfield.DynamicIndexLens
obj = (1,2,3)
@test get(obj, l) == 1
@test set(obj, l, true) == (true,2,3)

l = @lens _[2*begin]
@test l isa Setfield.DynamicIndexLens
obj = (1,2,3)
@test get(obj, l) == 2
@test set(obj, l, true) == (1,true,3)

one = 1
plustwo(x) = x + 2
l = @lens _.a[plustwo(begin) - one].b
obj = (a=(1, (a=10, b=20), 3), b=4)
@test get(obj, l) == 20
@test set(obj, l, true) == (a=(1, (a=10, b=true), 3), b=4)

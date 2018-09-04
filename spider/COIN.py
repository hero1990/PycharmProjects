import  pandas as pd
import numpy as np

d = pd.DataFrame(columns=['X10','X20','X50'])
ntest = 10**6
d.X10 = np.random.randint(0,2,ntest)
d.X20 = np.random.randint(0,2,ntest)
d.X50 = np.random.randint(0,2,ntest)

grp = d.groupby(d.eval('X10+X20+X50'))
grp.get_group(2).eval('10*X10+20*X20+50*X50').mean()

print(grp.get_group(2).eval('10*X10+20*X20+50*X50').mean())

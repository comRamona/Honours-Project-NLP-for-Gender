
# coding: utf-8

# In[1]:


from indexes import ACL_metadata
from functools import reduce
import _pickle as pkl
import os
from os.path import join
from os import environ
acl = ACL_metadata()


# In[2]:


ids = set(acl.df.index)
tf  = set()
justdl=[]
for f in acl.train_files:
    i = acl.get_id(f)

    tf.add(i)
    if not i in ids:
        justdl.append(i)
print(len(justdl))


# In[3]:


notdl=[]
for i in ids:
    if not i in tf:
        notdl.append(i)
print(len(notdl))


# In[4]:


with open("fileids.pkl","rb") as f:
    ids = pkl.load(f)
    train_files = [join(environ["AAN_DIR"],"papers_text/{0}.txt".format(fn)) for fn in ids]


# In[5]:


print(len(set(acl.train_files)))
print(len(set(ids)))
interesting = tf.intersection(ids)
print(len(interesting))
# with open("fileids.pkl","wb") as f:
#     pkl.dump(interesting,f)


# In[7]:


acl.df.loc[interesting]


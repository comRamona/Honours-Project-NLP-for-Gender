
# coding: utf-8

# In[1]:


import networkx as nx
import os
import matplotlib.pyplot as plt
import seaborn as sns
from metadata.metadata import ACL_metadata
from metadata import Gender
from collections import defaultdict
#get_ipython().run_line_magic('matplotlib', 'inline')


# In[2]:

os.environ["AAN_DIR"] = "/home/ramona/Desktop/Honours-LDA/aan"
g = nx.Graph()
acl = ACL_metadata()
auths = acl.auths
known_f = acl.known_f
known_m = acl.known_m
knowl_all = acl.known
unique_ids = acl.ids
new_unknown = acl.unk
df = acl.meta_df


# In[30]:


LIMIT_PAPERS = 5


def more_than_5_years(gender):
    if gender == Gender.female:
        known = known_f
    else:
        known = known_m
    counter = defaultdict(int)

    for i in range(1964, 2015):

        year = df[df["year"] == i]

        papers = year["authors"]

        for auths in papers:
            if(len(auths) == 0):
                continue
            auths = set(auths)
            for p, a in enumerate(auths):

                if a in known:
                    counter[a] += 1
    result = defaultdict(int)
    for k, v in counter.items():
        if v >= LIMIT_PAPERS:
            result[k] = v
    return result


# In[31]:


filter_fem = more_than_5_years(Gender.female)
filter_male = more_than_5_years(Gender.male)


# In[32]:


def get_collabs(gender):
    filtered = more_than_5_years(gender)
    collab_dic = defaultdict(int)
    for i in range(1964, 2015):

        year = df[df["year"] == i]

        papers = year["authors"]

        for auths in papers:
            if(len(auths) == 0):
                continue
            auths = set(auths)
            for p1, a1 in enumerate(auths):
                for p2, a2 in enumerate(auths):
                    if a1 != a2:
                        if a1 in filtered and (a2 in filter_fem or a2 in filter_male):
                            collab_dic[(a1, a2)] += 1
    return collab_dic


# In[33]:


collab_fem = get_collabs(Gender.female)


# In[62]:


G = nx.Graph()
for k, v in collab_fem.items():
    if v >= 5:
        G.add_edge(k[0], k[1], weight = v)
        print(k)

pos = nx.circular_layout(G)

edges = G.edges()
weights = [G[u][v]['weight'] for u,v in edges]

nx.draw_networkx(G, edges=edges)
nx.draw_networkx_edge_labels(G, pos)
# # Remove the axis
# plt.axis('off')
# # Show the plot
# plt.show()


# In[58]:


#nx.draw(G)
plt.show()
plt.savefig("../plots/collab_fem.pdf")


# Spatial Regression


This notebook covers a brief and gentle introduction to spatial econometrics in Python. To do that, we will use a set of Austin properties listed in AirBnb.

The core idea of spatial econometrics is to introduce a formal representation of space into the statistical framework for regression. This can be done in many ways: by including predictors based on space (e.g. distance to relevant features), by splitting the datasets into subsets that map into different geographical regions (e.g. [spatial regimes](http://pysal.readthedocs.io/en/latest/library/spreg/regimes.html)), by exploiting close distance to other observations to borrow information in the estimation (e.g. [kriging](https://en.wikipedia.org/wiki/Kriging)), or by introducing variables that put in relation their value at a given location with those in nearby locations, to give a few examples. Some of these approaches can be implemented with standard non-spatial techniques, while others require bespoke models that can deal with the issues introduced. In this short tutorial, we will focus on the latter group. In particular, we will introduce some of the most commonly used methods in the field of spatial econometrics.

The example we will use to demonstrate this draws on hedonic house price modelling. This a well-established methodology that was developed by [Rosen (1974)](https://www.sonoma.edu/users/c/cuellar/econ421/rosen-hedonic.pdf) that is capable of recovering the marginal willingness to pay for goods or services that are not traded in the market. In other words, this allows us to put an implicit price on things such as living close to a park or in a neighborhood with good quality of air. In addition, since hedonic models are based on linear regression, the technique can also be used to obtain predictions of house prices.

## Data

Before anything, let us load up the libraries we will use:


```python
%matplotlib inline

import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import pysal as ps
import libpysal as lps
import geopandas as gpd

sns.set(style="whitegrid")
```

Let us also set the paths to all the files we will need throughout the tutorial, which is only the original table of listings:


```python
# Adjust this to point to the right file in your computer
abb_link = 'data/listings.csv.gz'
```

And go ahead and load it up too:


```python
lst = pd.read_csv(abb_link)
```

## Baseline (nonspatial) regression

Before introducing explicitly spatial methods, we will run a simple linear regression model. This will allow us, on the one hand, set the main principles of hedonic modeling and how to interpret the coefficients, which is good because the spatial models will build on this; and, on the other hand, it will provide a baseline model that we can use to evaluate how meaningful the spatial extensions are.

Essentially, the core of a linear regression is to explain a given variable -the price of a listing $i$ on AirBnb ($P_i$)- as a linear function of a set of other characteristics we will collectively call $X_i$:

$$
\ln(P_i) = \alpha + \beta X_i + \epsilon_i
$$

For several reasons, it is common practice to introduce the price in logarithms, so we will do so here. Additionally, since this is a probabilistic model, we add an error term $\epsilon_i$ that is assumed to be well-behaved (i.i.d. as a normal).

For our example, we will consider the following set of explanatory features of each listed property:


```python
x = ['host_listings_count', 'bathrooms', 'bedrooms', 'beds', 'guests_included']
```

Additionally, we are going to derive a new feature of a listing from the `amenities` variable. Let us construct a variable that takes 1 if the listed property has a pool and 0 otherwise:


```python
def has_pool(a):
    if 'Pool' in a:
        return 1
    else:
        return 0
    
lst['pool'] = lst['amenities'].apply(has_pool)
```

For convenience, we will re-package the variables:


```python
yxs = lst.loc[:, x + ['pool', 'price']].dropna()
y = np.log(\
           yxs['price'].apply(lambda x: float(x.strip('$').replace(',', '')))\
           + 0.000001
          )
```

To run the model, we can use the `spreg` module in `PySAL`, which implements a standard OLS routine, but is particularly well suited for regressions on spatial data. Also, although for the initial model we do not need it, let us build a spatial weights matrix that connects every observation to its 8 nearest neighbors. This will allow us to get extra diagnostics from the baseline model.


```python
w = ps.knnW_from_array(lst.loc[\
                               yxs.index, \
                              ['longitude', 'latitude']\
                              ].values)
w.transform = 'R'
w
```




    <pysal.weights.weights.W at 0x11bdb5358>



At this point, we are ready to fit the regression:


```python
m1 = ps.spreg.OLS(y.values[:, None], yxs.drop('price', axis=1).values, \
                  w=w, spat_diag=True, \
                  name_x=yxs.drop('price', axis=1).columns.tolist(), name_y='ln(price)') 
```

To get a quick glimpse of the results, we can print its summary:


```python
print(m1.summary)
```

    REGRESSION
    ----------
    SUMMARY OF OUTPUT: ORDINARY LEAST SQUARES
    -----------------------------------------
    Data set            :     unknown
    Weights matrix      :     unknown
    Dependent Variable  :   ln(price)                Number of Observations:        5767
    Mean dependent var  :      5.1952                Number of Variables   :           7
    S.D. dependent var  :      0.9455                Degrees of Freedom    :        5760
    R-squared           :      0.4042
    Adjusted R-squared  :      0.4036
    Sum squared residual:    3071.189                F-statistic           :    651.3958
    Sigma-square        :       0.533                Prob(F-statistic)     :           0
    S.E. of regression  :       0.730                Log likelihood        :   -6366.162
    Sigma-square ML     :       0.533                Akaike info criterion :   12746.325
    S.E of regression ML:      0.7298                Schwarz criterion     :   12792.944
    
    ------------------------------------------------------------------------------------
                Variable     Coefficient       Std.Error     t-Statistic     Probability
    ------------------------------------------------------------------------------------
                CONSTANT       4.0976886       0.0223530     183.3171506       0.0000000
     host_listings_count      -0.0000130       0.0001790      -0.0726772       0.9420655
               bathrooms       0.2947079       0.0194817      15.1273879       0.0000000
                bedrooms       0.3274226       0.0159666      20.5067654       0.0000000
                    beds       0.0245741       0.0097379       2.5235601       0.0116440
         guests_included       0.0075119       0.0060551       1.2406028       0.2148030
                    pool       0.0888039       0.0221903       4.0019209       0.0000636
    ------------------------------------------------------------------------------------
    
    REGRESSION DIAGNOSTICS
    MULTICOLLINEARITY CONDITION NUMBER            9.260
    
    TEST ON NORMALITY OF ERRORS
    TEST                             DF        VALUE           PROB
    Jarque-Bera                       2     1358479.047           0.0000
    
    DIAGNOSTICS FOR HETEROSKEDASTICITY
    RANDOM COEFFICIENTS
    TEST                             DF        VALUE           PROB
    Breusch-Pagan test                6        1414.297           0.0000
    Koenker-Bassett test              6          36.756           0.0000
    
    DIAGNOSTICS FOR SPATIAL DEPENDENCE
    TEST                           MI/DF       VALUE           PROB
    Lagrange Multiplier (lag)         1         255.796           0.0000
    Robust LM (lag)                   1          13.039           0.0003
    Lagrange Multiplier (error)       1         278.752           0.0000
    Robust LM (error)                 1          35.995           0.0000
    Lagrange Multiplier (SARMA)       2         291.791           0.0000
    
    ================================ END OF REPORT =====================================


Results are largely unsurprising, but nonetheless reassuring. Both an extra bedroom and an extra bathroom increase the final price around 30%. Accounting for those, an extra bed pushes the price about 2%. Neither the number of guests included nor the number of listings the host has in total have a significant effect on the final price.

Including a spatial weights object in the regression buys you an extra bit: the summary provides results on the diagnostics for spatial dependence. These are a series of statistics that test whether the residuals of the regression are spatially correlated, against the null of a random distribution over space. If the latter is rejected a key assumption of OLS, independently distributed error terms, is violated. Depending on the structure of the spatial pattern, different strategies have been defined within the spatial econometrics literature to deal with them. If you are interested in this, a very recent and good resource to check out is [Anselin & Rey (2015)](https://geodacenter.asu.edu/category/access/public/spatial-regress). The main summary from the diagnostics for spatial dependence is that there is clear evidence to reject the null of spatial randomness in the residuals, hence an explicitly spatial approach is warranted.

## Spatially lagged exogenous regressors (`WX`)

The first and most straightforward way to introduce space is by "spatially lagging" one of the explanatory variables. Mathematically, this can be expressed as follows:

$$
\ln(P_i) = \alpha + \beta X_i + \delta \sum_j w_{ij} X'_i + \epsilon_i
$$

where $X'_i$ is a subset of $X_i$, although it could encompass all of the explanatory variables, and $w_{ij}$ is the $ij$-th cell of a spatial weights matrix $W$. Because $W$ assigns non-zero values only to spatial neighbors, if $W$ is row-standardized (customary in this context), then $\sum_j w_{ij} X'_i$ captures the average value of $X'_i$ in the surroundings of location $i$. This is what we call the *spatial lag* of $X_i$. Also, since it is a spatial transformation of an explanatory variable, the standard estimation approach -OLS- is sufficient: spatially lagging the variables does not violate any of the assumptions on which OLS relies.

Usually, we will want to spatially lag variables that we think may affect the price of a house in a given location. For example, one could think that pools represent a visual amenity. If that is the case, then listed properties surrounded by other properties with pools might, everything else equal, be more expensive. To calculate the number of pools surrounding each property, we can build an alternative weights matrix that we do not row-standardize:


```python
w_pool = ps.knnW_from_array(lst.loc[\
                               yxs.index, \
                              ['longitude', 'latitude']\
                              ].values)
yxs_w = yxs.assign(w_pool=ps.lag_spatial(w_pool, yxs['pool'].values))
```

And now we can run the model, which has the same setup as `m1`, with the exception that it includes the number of AirBnb properties with pools surrounding each house:


```python
m2 = ps.spreg.OLS(y.values[:, None], \
                  yxs_w.drop('price', axis=1).values, \
                  w=w, spat_diag=True, \
                  name_x=yxs_w.drop('price', axis=1).columns.tolist(), name_y='ln(price)') 
```


```python
print(m2.summary)
```

    REGRESSION
    ----------
    SUMMARY OF OUTPUT: ORDINARY LEAST SQUARES
    -----------------------------------------
    Data set            :     unknown
    Weights matrix      :     unknown
    Dependent Variable  :   ln(price)                Number of Observations:        5767
    Mean dependent var  :      5.1952                Number of Variables   :           8
    S.D. dependent var  :      0.9455                Degrees of Freedom    :        5759
    R-squared           :      0.4044
    Adjusted R-squared  :      0.4037
    Sum squared residual:    3070.363                F-statistic           :    558.6139
    Sigma-square        :       0.533                Prob(F-statistic)     :           0
    S.E. of regression  :       0.730                Log likelihood        :   -6365.387
    Sigma-square ML     :       0.532                Akaike info criterion :   12746.773
    S.E of regression ML:      0.7297                Schwarz criterion     :   12800.053
    
    ------------------------------------------------------------------------------------
                Variable     Coefficient       Std.Error     t-Statistic     Probability
    ------------------------------------------------------------------------------------
                CONSTANT       4.0906444       0.0230571     177.4134022       0.0000000
     host_listings_count      -0.0000108       0.0001790      -0.0603617       0.9518697
               bathrooms       0.2948787       0.0194813      15.1365024       0.0000000
                bedrooms       0.3277450       0.0159679      20.5252404       0.0000000
                    beds       0.0246650       0.0097377       2.5329419       0.0113373
         guests_included       0.0076894       0.0060564       1.2696250       0.2042695
                    pool       0.0725756       0.0257356       2.8200486       0.0048181
                  w_pool       0.0188875       0.0151729       1.2448141       0.2132508
    ------------------------------------------------------------------------------------
    
    REGRESSION DIAGNOSTICS
    MULTICOLLINEARITY CONDITION NUMBER            9.605
    
    TEST ON NORMALITY OF ERRORS
    TEST                             DF        VALUE           PROB
    Jarque-Bera                       2     1368880.320           0.0000
    
    DIAGNOSTICS FOR HETEROSKEDASTICITY
    RANDOM COEFFICIENTS
    TEST                             DF        VALUE           PROB
    Breusch-Pagan test                7        1565.566           0.0000
    Koenker-Bassett test              7          40.537           0.0000
    
    DIAGNOSTICS FOR SPATIAL DEPENDENCE
    TEST                           MI/DF       VALUE           PROB
    Lagrange Multiplier (lag)         1         255.124           0.0000
    Robust LM (lag)                   1          13.448           0.0002
    Lagrange Multiplier (error)       1         276.862           0.0000
    Robust LM (error)                 1          35.187           0.0000
    Lagrange Multiplier (SARMA)       2         290.310           0.0000
    
    ================================ END OF REPORT =====================================


Results are largely consistent with the original model. Also, incidentally, the number of pools surrounding a property does not appear to have any significant effect on the price of a given property. This could be for a host of reasons: maybe AirBnb customers do not value the number of pools surrounding a property where they are looking to stay; but maybe they do but our dataset only allows us to capture the number of pools in *other* AirBnb properties, which is not necessarily a good proxy of the number of pools in the immediate surroundings of a given property.

## Spatially lagged endogenous regressors (`WY`)

In a similar way to how we have included the spatial lag, one could think the prices of houses surrounding a given property also enter its own price function. In math terms, this implies the following:

$$
\ln(P_i) = \alpha + \lambda \sum_j w_{ij} \ln(P_i) + \beta X_i + \epsilon_i
$$

This is essentially what we call a *spatial lag* model in spatial econometrics. Two calls for caution:

1. Unlike before, this specification *does* violate some of the assumptions on which OLS relies. In particular, it is including an endogenous variable on the right-hand side. This means we need a new estimation method to obtain reliable coefficients. The technical details of this go well beyond the scope of this workshop (although, if you are interested, go check [Anselin & Rey, 2015](https://geodacenter.asu.edu/category/access/public/spatial-regress)). But we can offload those to `PySAL` and use the `GM_Lag` class, which implements the state-of-the-art approach to estimate this model.
1. A more conceptual *gotcha*: you might be tempted to read the equation above as the effect of the price in neighboring locations $j$ on that of location $i$. This is not exactly the exact interpretation. Instead, we need to realize this is all assumed to be a "joint decission": rather than some houses setting their price first and that having a subsequent effect on others, what the equation models is an interdependent process by which each owner sets her own price *taking into account* the price that will be set in neighboring locations. This might read a bit like a technical subtlety and, to some extent, it is; but it is important to keep it in mind when you are interpreting the results.

Let us see how you would run this using `PySAL`:


```python
m3 = ps.spreg.GM_Lag(y.values[:, None], yxs.drop('price', axis=1).values, \
                  w=w, spat_diag=True, \
                  name_x=yxs.drop('price', axis=1).columns.tolist(), name_y='ln(price)') 
```


```python
print(m3.summary)
```

    REGRESSION
    ----------
    SUMMARY OF OUTPUT: SPATIAL TWO STAGE LEAST SQUARES
    --------------------------------------------------
    Data set            :     unknown
    Weights matrix      :     unknown
    Dependent Variable  :   ln(price)                Number of Observations:        5767
    Mean dependent var  :      5.1952                Number of Variables   :           8
    S.D. dependent var  :      0.9455                Degrees of Freedom    :        5759
    Pseudo R-squared    :      0.4224
    Spatial Pseudo R-squared:  0.4056
    
    ------------------------------------------------------------------------------------
                Variable     Coefficient       Std.Error     z-Statistic     Probability
    ------------------------------------------------------------------------------------
                CONSTANT       3.7085715       0.1075621      34.4784213       0.0000000
     host_listings_count      -0.0000587       0.0001765      -0.3324585       0.7395430
               bathrooms       0.2857932       0.0193237      14.7897969       0.0000000
                bedrooms       0.3272598       0.0157132      20.8270544       0.0000000
                    beds       0.0239548       0.0095848       2.4992528       0.0124455
         guests_included       0.0065147       0.0059651       1.0921407       0.2747713
                    pool       0.0891100       0.0218383       4.0804521       0.0000449
             W_ln(price)       0.0785059       0.0212424       3.6957202       0.0002193
    ------------------------------------------------------------------------------------
    Instrumented: W_ln(price)
    Instruments: W_bathrooms, W_bedrooms, W_beds, W_guests_included,
                 W_host_listings_count, W_pool
    
    DIAGNOSTICS FOR SPATIAL DEPENDENCE
    TEST                           MI/DF       VALUE           PROB
    Anselin-Kelejian Test             1          31.545          0.0000
    ================================ END OF REPORT =====================================


As we can see, results are again very similar in all the other variable. It is also very clear that the estimate of the spatial lag of price is statistically significant. This points to evidence that there are processes of spatial interaction between property owners when they set their price.

## Prediction performance of spatial models

Even if we are not interested in the interpretation of the model to learn more about how alternative factors determine the price of an AirBnb property, spatial econometrics can be useful. In a purely predictive setting, the use of explicitly spatial models is likely to improve accuracy in cases where space plays a key role in the data generating process. To have a quick look at this issue, we can use the mean squared error (MSE), a standard metric of accuracy in the machine learning literature, to evaluate whether explicitly spatial models are better than traditional, non-spatial ones:


```python
from sklearn.metrics import mean_squared_error as mse

mses = pd.Series({'OLS': mse(y, m1.predy.flatten()), \
                     'OLS+W': mse(y, m2.predy.flatten()), \
                     'Lag': mse(y, m3.predy_e)
                    })
mses.sort_values()
```




    Lag      0.531327
    OLS+W    0.532402
    OLS      0.532545
    dtype: float64



We can see that the inclusion of the number of surrounding pools (which was insignificant) only marginally reduces the MSE. The inclusion of the spatial lag of price, however, does a better job at improving the accuracy of the model.

## Exercise

> *Run a regression including both the spatial lag of pools and of the price. How does its predictive performance compare?*


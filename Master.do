global path "C:\Users\Pablo Uribe\Documents\GitHub\wb\yemen"

qui do "${path}\password.do"



do "${path}\Step 0 - Master CfN data.do"
statapush, ${tokens} message(CfN)


do "${path}\Step 1 - Simulations.do"
statapush, ${tokens} message(Long simulations)


do "${path}\Step 1 - Simulations 2.do"
statapush, ${tokens} message(Aggregated simulations)


do "${path}\Step 2 - Plots.do"
statapush, ${tokens} message(First batch of plots)


do "${path}\Step 2 - Plots 2.do"
statapush, ${tokens} message(FINISHED RUNNING)

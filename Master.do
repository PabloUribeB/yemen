global dos "C:\Users\Pablo Uribe\Documents\GitHub\wb\yemen"

qui do "${dos}\password.do"



do "${dos}\Step 0 - Master CfN data.do"
statapush, ${tokens} message(CfN)


do "${dos}\Step 1 - Simulations.do"
statapush, ${tokens} message(Long simulations)


do "${dos}\Step 1 - Simulations 2.do"
statapush, ${tokens} message(Aggregated simulations)


do "${dos}\Step 2 - Plots.do"
statapush, ${tokens} message(First batch of plots)


do "${dos}\Step 2 - Plots 2.do"
statapush, ${tokens} message(FINISHED RUNNING)

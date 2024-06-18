global dos "C:\Users\Pablo Uribe\Documents\GitHub\wb\yemen"

qui do "${dos}\password.do"


do "${dos}\power\Step 1 - Simulations.do"
statapush, ${tokens} message(Long simulations)


do "${dos}\power\Step 1 - Simulations 2.do"
statapush, ${tokens} message(Aggregated simulations)


do "${dos}\power\Step 2 - Plots.do"
statapush, ${tokens} message(First batch of plots)


do "${dos}\power\Step 2 - Plots 2.do"
statapush, ${tokens} message(FINISHED RUNNING)


statapush using "${dos}\randomization_inference\Step 1 - Simulations.do", ${tokens} message(Finished running)
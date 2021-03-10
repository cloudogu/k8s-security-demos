# Security Context Demo

![Clusters, Namespaces and Pods](https://www.plantuml.com/plantuml/svg/dP2nQiD038RtUmhX3fbCQGF1OsWWIw4lK3g8aseEsvBHtRM1adUlR3maQpJfVdtt2NJC1QtKQGnvI3AZuGH92jitHeQ_0F26SUXDgz19HpLuUjtZdcYPg17RbhuS3br7uHfkH6Yclwla_kiT57MQLLZA0zi0pYfboyvhBV8WIWpDUvVXDDPSs1gNEpsx7NiVVU34sLyCkyonZUMoQy0PyFgKFidbwwPF4f_NfgqoM_f98_TC6q4Q1xOsLz8byVNNS6GXl-a_)

`apply.sh` deploys the applications required for the demos.

Then, you can can start the interactive demo:

```bash
cd demo
./interactive-demo.sh
```

Note if you got [bat](https://github.com/sharkdp/bat) on your `PATH`, the output will prettier.

Alternatively, you could print a transcript of the demo for doing the demo manually

```bash
cd demo
PRINT_ONLY=true ./interactive-demo.sh
```
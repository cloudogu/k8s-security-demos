#!/usr/bin/env bash
kubectl delete rolebinding default:psp:privileged
kubectl delete pod --all
kubectl get pod
kubectl describe rs $(kubectl get rs  | awk '/nginx-read-only-fs-empty-dirs/ {print $1;exit}')

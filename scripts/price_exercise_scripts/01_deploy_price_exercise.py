#!/usr/bin/python3
from brownie import MockV3Aggregator, PriceContract, LinkToken, MockOracle, config, network
from scripts.helpful_scripts import (
    get_verify_status,
    get_account,
    get_contract,
    LOCAL_BLOCKCHAIN_ENVIRONMENTS
)
from scripts.deploy_mocks import deploy_mocks

def deploy_price_exercise_consumer():
    jobId = config["networks"][network.show_active()]["jobId"]
    fee = config["networks"][network.show_active()]["fee"]
    account = get_account()
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        if len(MockOracle) <= 0:
            deploy_mocks()
        oracle = MockOracle[-1].address
        link_token = LinkToken[-1].address
        btc_usd_price_feed = MockV3Aggregator[-1].address
    else:
        btc_usd_price_feed = config["networks"][network.show_active()]["btc_usd_price_feed"]
        oracle = config["networks"][network.show_active()]["oracle"]
        link_token = config["networks"][network.show_active()]["link_token"]
        price_exercise = PriceContract.deploy(
            oracle,
            jobId,
            fee,
            link_token,
            btc_usd_price_feed,
            {"from": account},
            publish_source=get_verify_status()
        )
    print(f"Price Exercise deployed to {price_exercise.address}")
    return price_exercise


def main():
    deploy_price_exercise_consumer()
import { useState } from "react";
import {
  useAccount,
  useWaitForTransaction,
  useTransactionManager,
  useTransactions,
  useTransaction,
} from "@starknet-react/core";
import { useQuery } from "@apollo/client";
import {
  getDiscoveryByTxHash,
  getLatestDiscoveries,
} from "../hooks/graphql/queries";
import KeyboardControl, { ButtonData } from "./KeyboardControls";
import { NullDiscovery } from "../types";
import { NullAdventurer } from "../types";
import { useAdventurer } from "../context/AdventurerProvider";

const Discovery = () => {
  const { account } = useAccount();
  const { hashes } = useTransactionManager();

  const currentHash = hashes[hashes.length - 1];
  const currentTransaction = useTransaction({ hash: currentHash });
  console.log(
    currentTransaction.data?.entry_point_selector,
    currentTransaction
  );
  const checkExplore =
    currentTransaction.data?.entry_point_selector == "explore";

  const { adventurer, handleUpdateAdventurer } = useAdventurer();
  const { data, status, isLoading, error } = useWaitForTransaction({
    hash: currentHash,
    watch: true,
  });
  const formatAdventurer = adventurer ? adventurer.adventurer : NullAdventurer;

  const { data: latestDiscoveriesData, error: latestDiscoveriesError } =
    useQuery(getLatestDiscoveries, {
      variables: {
        adventurerId: formatAdventurer?.id,
      },
      pollInterval: 5000,
    });

  const latestDiscoveries = latestDiscoveriesData
    ? latestDiscoveriesData.discoveries
    : [];

  return (
    <div className="flex flex-col gap-5 m-auto">
      {(checkExplore && data?.status != "ACCEPTED_ON_L2") ||
      (checkExplore && data?.status != "ACCEPTED_ON_L1") ? (
        <>
          <div className="flex flex-col">Hash: {currentHash}</div>
          {data?.status == "RECEIVED" ||
            (data?.status == "PENDING" && (
              <div className="loading-ellipsis">Loading</div>
            ))}
          {error && <div>Error: {JSON.stringify(error)}</div>}
          {data && <div>Status: {data.status}</div>}
        </>
      ) : latestDiscoveries.length > 0 ? (
        <>
          <p>Recent discoveries:</p>
          <div className="flex flex-col gap-2">
            {latestDiscoveries.map((discovery: any, index: number) => (
              <p key={index}>Discovered {discovery.discoveryType}</p>
            ))}
          </div>
        </>
      ) : (
        <p>You have not yet made any discoveries!</p>
      )}
    </div>
  );
};

export default Discovery;

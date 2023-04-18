import { useState } from "react";
import { useAccount, useTransaction } from "@starknet-react/core";
import { useQuery } from "@apollo/client";
import { getDiscoveryByTxHash } from "../hooks/graphql/queries";
import KeyboardControl, { ButtonData } from "./KeyboardControls";
import { NullDiscovery } from "../types";
import { NullAdventurerProps } from "../types";
import { useAdventurer } from "../context/AdventurerProvider";

const [loading, setLoading] = useState(false);

const { adventurer, handleUpdateAdventurer } = useAdventurer();

const formatAdventurer = adventurer ? adventurer : NullAdventurerProps;

const [hash, setHash] = useState<string | undefined>(undefined);
const transactions = useTransaction({ hash });

const {
  loading: discoveryByTxHashLoading,
  error: discoveryByTxHashError,
  data: discoveryByTxHashData,
  refetch: discoveryByTxHashRefetch,
} = useQuery(getDiscoveryByTxHash, {
  variables: {
    id: "",
    hash: "",
  },
  pollInterval: 5000,
});

const Discovery = () => {
  const { account } = useAccount();
  const accountAddress = account ? account.address : "0x0";
  const { data: discoveryData } = useQuery(getDiscoveryByTxHash, {
    variables: {
      owner: accountAddress,
      hash: "",
    },
  });

  const discovery = discoveryData
    ? discoveryData.discoveries[0]
    : NullDiscovery;

  return (
    <div className="bg-black">
      <p>{discovery.discoveryType}</p>
      <p>{discovery.discoveryEmoji}</p>
    </div>
  );
};

export default Discovery;

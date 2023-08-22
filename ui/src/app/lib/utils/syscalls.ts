import { InvokeTransactionReceiptResponse } from "starknet";
import { GameData } from "@/app/components/GameData";
import { FormData } from "@/app/types";
import { useContracts } from "@/app/hooks/useContracts";
import {
  useAccount,
  useContractWrite,
  useTransactionManager,
  useWaitForTransaction,
} from "@starknet-react/core";
import useTransactionCartStore from "@/app/hooks/useTransactionCartStore";
import useLoadingStore from "@/app/hooks/useLoadingStore";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import { getKeyFromValue, stringToFelt, getRandomNumber } from ".";
import { parseEvents } from "./parseEvents";

export function syscalls() {
  const gameData = new GameData();

  const { gameContract, lordsContract } = useContracts();
  const { addTransaction } = useTransactionManager();
  const { account } = useAccount();
  const { data: queryData, resetDataUpdated, setData } = useQueriesStore();

  const formatAddress = account ? account.address : "0x0";
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const calls = useTransactionCartStore((state) => state.calls);
  const handleSubmitCalls = useTransactionCartStore(
    (state) => state.handleSubmitCalls
  );
  const startLoading = useLoadingStore((state) => state.startLoading);
  const stopLoading = useLoadingStore((state) => state.stopLoading);
  const setTxAccepted = useLoadingStore((state) => state.setTxAccepted);
  const hash = useLoadingStore((state) => state.hash);
  const setTxHash = useLoadingStore((state) => state.setTxHash);
  const { writeAsync } = useContractWrite({ calls });

  const spawn = async (formData: FormData) => {
    const mintLords = {
      contractAddress: lordsContract?.address ?? "",
      entrypoint: "mint",
      calldata: [formatAddress, (100 * 10 ** 18).toString(), "0"],
    };
    addToCalls(mintLords);

    const approveLordsTx = {
      contractAddress: lordsContract?.address ?? "",
      entrypoint: "approve",
      calldata: [gameContract?.address ?? "", (100 * 10 ** 18).toString(), "0"],
    };
    addToCalls(approveLordsTx);

    const mintAdventurerTx = {
      contractAddress: gameContract?.address ?? "",
      entrypoint: "start",
      calldata: [
        "0x0628d41075659afebfc27aa2aab36237b08ee0b112debd01e56d037f64f6082a",
        getKeyFromValue(gameData.ITEMS, formData.startingWeapon) ?? "",
        stringToFelt(formData.name).toString(),
        getRandomNumber(8000),
        getKeyFromValue(gameData.CLASSES, formData.class) ?? "",
        "1",
        formData.startingStrength,
        formData.startingDexterity,
        formData.startingVitality,
        formData.startingIntelligence,
        formData.startingWisdom,
        formData.startingCharisma,
      ],
    };

    addToCalls(mintAdventurerTx);
    startLoading(
      "Create",
      "Spawning Adventurer",
      "adventurersByOwnerQuery",
      undefined,
      `You have spawned ${formData.name}!`
    );
    await handleSubmitCalls(writeAsync).then((tx: any) => {
      if (tx) {
        setTxHash(tx.transaction_hash);
        addTransaction({
          hash: tx?.transaction_hash,
          metadata: {
            method: `Spawn ${formData.name}`,
          },
        });
      }
    });
    // const { data } = useWaitForTransaction({
    //   hash,
    //   watch: true,
    //   onAcceptedOnL2: () => {
    //     setTxAccepted(true);
    //   },
    //   onRejected: () => {
    //     stopLoading("Rejected");
    //   },
    // }) as { data: InvokeTransactionReceiptResponse };
    // resetDataUpdated("adventurersByOwnerQuery");
    // const events = parseEvents(data);
    // setData("adventurersByOwnerQuery", {
    //   adventurers: [
    //     ...(queryData.adventurersByOwnerQuery?.adventurers ?? []),
    //     events.find((event) => event.name === "StartGame").data[0],
    //   ],
    // });
    // setData("adventurerByIdQuery", {
    //   adventurers: [events.find((event) => event.name === "StartGame").data[0]],
    // });
  };

  return { spawn };
}

import { AccountChangeEventHandler } from "get-starknet-core";
import { AccountInterface, Account } from "starknet";
import { Connector } from "@starknet-react/core";
import { shortenHex } from "@/app/lib/utils";
import { ConnectorData } from "starknetkit/dist/connectors/connector";

export class ArcadeConnector extends Connector {
  private _account: AccountInterface | Account;

  constructor(account: AccountInterface | Account) {
    super();
    this._account = account;
  }

  available(): boolean {
    // Implement your logic here.
    return true;
  }

  async ready(): Promise<boolean> {
    // Implement your logic here.
    return true;
  }

  async chainId(): Promise<bigint> {
    return BigInt(0);
  }

  async connect(): Promise<ConnectorData> {
    if (!this._account) {
      throw new Error("account not found");
    }
    return {
      account: this._account.address,
      chainId: await this.chainId(),
    };
  }

  async disconnect(): Promise<void> {
    Promise.resolve(this._account == null);
  }

  async initEventListener(
    accountChangeCb: AccountChangeEventHandler
  ): Promise<void> {
    return Promise.resolve();
  }

  async removeEventListener(
    accountChangeCb: AccountChangeEventHandler
  ): Promise<void> {
    return Promise.resolve();
  }

  async account(): Promise<AccountInterface> {
    return Promise.resolve(this._account);
  }

  get id(): string {
    // Implement your logic here.
    return shortenHex(this._account?.address.toString()!) || "ArcadeAccount";
  }

  get name(): string {
    // Implement your logic here.
    return this._account?.address.toString() || "Arcade Account";
  }

  get icon(): {
    /** Dark-mode icon. */
    dark?: string;
    /** Light-mode icon. */
    light?: string;
  } {
    return {
      light: "my-icon-url",
      dark: "my-icon-url",
    };
  }
}

import React, { ReactNode, createContext, useContext, useState } from 'react';
import { useAccount } from '@starknet-react/core';
import { useBurner } from './lib/burner';

const BurnerContext = createContext({});

type Props = {
    children: ReactNode;
};

export const BurnerProvider = ({ children }: Props) => {
    const [data, setData] = useState(null);

    return (
        <BurnerContext.Provider value={{ data, setData }}>
            {children}
        </BurnerContext.Provider>
    );
};

export const useBurnerContext = () => {
    const context = useContext(BurnerContext);

    const { account: master } = useAccount()


    const { listConnectors, get, list, create, isDeploying, account } = useBurner();

    if (!context) {
        throw new Error('useMyContext must be used within a BurnerProvider');
    }

    return { context: context, burner: { listConnectors, get, list, create, isDeploying, account: account ? account : master } };
};
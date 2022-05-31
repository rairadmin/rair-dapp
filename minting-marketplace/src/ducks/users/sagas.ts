import { getUserComplete, getUserError } from "./actions";
import { put, call, takeLatest } from "redux-saga/effects";
import * as types from "./types";
import axios, { AxiosResponse, AxiosError } from "axios";

export type UserType = {
  adminNFT: string;
  avatar: string | null;
  creationDate: string;
  email: string | null;
  firstName: string | null;
  lastName: string | null;
  nickName: string | null;
  nonce: string;
  publicAddress: string;
  _id: string;
};

export type UserResponseType = {
  succes: boolean;
  user: UserType;
};

export type Params = { publicAddress: string, type: string }

export function* getUser({ publicAddress }: Params) {
  try {
    const response: AxiosResponse = yield call(
      axios.get,
      `/api/users/${publicAddress}`
    );

    if (response.data.user !== undefined && response.status === 200) {
      yield put(getUserComplete(response.data.user));
    }
  } catch (error) {
    const errors = error as AxiosError;
    if (errors.response !== undefined) {
      if (errors.response.status === 404) {
        const errorDirec = "This address does not exist";
        yield put(getUserError(errorDirec));
      } else if (errors.response.status === 500) {
        const errorServer = "Sorry. an internal server problem has occurred";
        yield put(getUserError(errorServer));
      } else {
        yield put(getUserError(errors.message));
      }
    } else {
      const errorConex = "Connection error!";
      yield put(getUserError(errorConex));
    }
  }
}

export function* sagaUser() {
  yield takeLatest(types.GET_USER_START, getUser);
}

#if defined _param_test_stocks_included
    #endinput
#endif
#define _param_test_stocks_included

/*******************************************************************************
 * STOCKS
 ******************************************************************************/

stock bool:isInvalidNumberOfParams(const function[], found, expected) {
    if (found != expected) {
        log_error(AMX_ERR_NATIVE, "[%s] Expected %d parameters, found %d", function, expected, found);
        return true;
    }

    return false;
}

stock bool:isInvalidNumberOfParamsInRange(const function[], found, expected_min, expected_max) {
    if (found < expected_min || expected_max < found) {
        log_error(AMX_ERR_NATIVE, "[%s] Expected %d to %d parameters, found %d",
                function,
                expected_min,
                expected_max,
                found);
        return true;
    }

    return false;
}

stock bool:isInvalidNumberOfParamsMin(const function[], found, expected_min) {
    if (found < expected_min) {
        log_error(AMX_ERR_NATIVE, "[%s] Expected more than %d parameters, found %d",
                function,
                expected_min,
                found);
        return true;
    }

    return false;
}

stock bool:isInvalidNumberOfParamsMax(const function[], found, expected_max) {
    if (found < expected_min) {
        log_error(AMX_ERR_NATIVE, "[%s] Expected less than %d parameters, found %d",
                function,
                expected_max,
                found);
        return true;
    }

    return false;
}

stock bool:isInvalidPlayerIndexParam(const function[], id) {
    if (id < 1 || MaxClients < id) {
        log_error(
                AMX_ERR_NATIVE,
                "[%s] Invalid player index specified: %d",
                function,
                id);
        return true;
    }

    return false;
}

stock bool:isInvalidPlayerConnectedParam(const function[], id) {
    if (!is_user_connected(id)) {
        log_error(
                AMX_ERR_NATIVE,
                "[%s] User is not connected: %d",
                function,
                id);
        return true;
    }

    return false;
}


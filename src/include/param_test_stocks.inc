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
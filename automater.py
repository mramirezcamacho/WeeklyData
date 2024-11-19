import datetime
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.keys import Keys
from selenium.common.exceptions import NoSuchElementException, StaleElementReferenceException
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time

# Set up the WebDriver (make sure chromedriver is in your PATH)


def read_first_two_lines(file_path):
    try:
        with open(file_path, 'r') as file:
            first_line = file.readline().strip()  # Read first line
            second_line = file.readline().strip()  # Read second line
            return first_line, second_line
    except FileNotFoundError:
        return None
    except KeyboardInterrupt:
        print("\nKeyboardInterrupt caught! Exiting gracefully.")
        return None


def start(bigData=True):
    # Setup ChromeOptions to suppress logs
    chrome_options = Options()
    # Suppress logs (INFO, WARNING, ERROR, FATAL)
    chrome_options.add_argument("--log-level=3")

    # Additional option to suppress DevTools and SSL errors
    chrome_options.add_argument("--disable-logging")
    chrome_options.add_argument("--disable-extensions")
    chrome_options.add_argument("--ignore-certificate-errors")

    driver = webdriver.Chrome(options=chrome_options)

    # Open a website
    if bigData:
        driver.get("https://bigdata.intra.didiglobal.com/analysis_platform_static/board.html#/?type=reportView&reportId=80601&source=market&showMetric=false&subReportId=162327")
    else:
        driver.get("http://star.intra.didiglobal.com/?menuId=C6DIHi0RC")

    return driver


def quit(driver):
    driver.quit()


def check_element(driver, xpath):
    try:
        driver.find_element("xpath", xpath)
        return True
    except NoSuchElementException:
        try:
            driver.find_element(By.XPATH, xpath)
            return True
        except:
            pass
        return False
    except KeyboardInterrupt:
        print("\nKeyboardInterrupt caught! Exiting gracefully.")
        exit()


def writeInBox(driver, input_xpath, textToInsert):
    while True:
        try:
            # Locate the input field using the provided XPath
            try:
                date_input = driver.find_element("xpath", input_xpath)
            except KeyboardInterrupt:
                print("\nKeyboardInterrupt caught! Exiting gracefully.")
                exit()
            except:
                date_input = driver.find_element(By.XPATH, input_xpath)

            # Clear the input field and enter the text
            date_input.clear()  # Clears any pre-existing value in the input
            date_input.send_keys(textToInsert)

            # Exit the loop if the input was successfully found and text inserted
            break

        except KeyboardInterrupt:
            print("\nKeyboardInterrupt caught! Exiting gracefully.")
            exit()
        except NoSuchElementException:
            print("Element not found, waiting for 5 seconds and retrying...")
            time.sleep(5)
        except StaleElementReferenceException:
            print("Stale element reference, waiting for 5 seconds and retrying...")
            time.sleep(5)


def pushKey(driver, xpath, keys: list):
    element = driver.find_element("xpath", xpath)
    sum = ''
    for key in keys:
        sum += key
    element.send_keys(sum)


def get_last_sunday():
    today = datetime.date.today()
    offset = (today.weekday() + 1) % 7
    last_sunday = today - datetime.timedelta(days=offset)
    return last_sunday


def get_third_monday_backwards(last_sunday):
    third_monday = last_sunday - \
        datetime.timedelta(days=(last_sunday.weekday()) + (2 * 7))
    return third_monday


def getDates():
    last_sunday = get_last_sunday()
    third_monday = get_third_monday_backwards(last_sunday)
    return f'{third_monday} - {last_sunday}'


def click_button(driver, button_xpath, deleteStuff=False):
    try:
        button = driver.find_element("xpath", button_xpath)
    except KeyboardInterrupt:
        print("\nKeyboardInterrupt caught! Exiting gracefully.")
        exit()
    except:
        button = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.XPATH, button_xpath)))

    button.click()
    if deleteStuff:
        pushKey(driver, button_xpath, [Keys.CONTROL, "a"])
        pushKey(driver, button_xpath, [Keys.BACKSPACE])
        button.send_keys(getDates())


def checkCredentials(driver, file_path='credentials.txt'):
    result = read_first_two_lines(file_path)

    if result is None:
        print("File not found.")
    else:
        while True:
            try:
                first_line, second_line = result
                writeInBox(driver, '//*[@id="username"]', first_line)
                writeInBox(driver, '//*[@id="password"]', second_line)
                while True:
                    try:
                        click_button(driver, '//*[@id="submit"]')
                        break
                    except KeyboardInterrupt:
                        print("\nKeyboardInterrupt caught! Exiting gracefully.")
                        exit()
                    except:
                        print('Submit button not found')
                break
            except KeyboardInterrupt:
                print("\nKeyboardInterrupt caught! Exiting gracefully.")
                exit()
            except:
                print('Credentials found, trying again the login')
                time.sleep(5)
    return


def is_page_loading(driver):
    return driver.execute_script("return document.readyState") != "complete"


def enterDiDiDashboard(driver, bigData=True):
    # XPath for the submit button
    checkCredentials(driver)
    xpath = '//*[@id="submit"]'
    while check_element(driver, xpath) and 'https://me.didiglobal.com/project/stargate-auth/html/login.html' in driver.current_url:
        print("Logging in...")
        time.sleep(5)
    if bigData:
        target_url = 'https://bigdata.intra.didiglobal.com/analysis_platform_static/board.html#/?type=reportView&reportId=80601&source=market&showMetric=false&subReportId=162327'
    else:
        target_url = 'http://star.intra.didiglobal.com/?menuId=C6DIHi0RC'
    while driver.current_url != target_url:
        print("URL is different, waiting...")
        time.sleep(5)
        if not bigData:
            break

    while is_page_loading(driver):
        print("Page is still loading...")
        time.sleep(1)  # Sleep for a short time to avoid overloading the loop
    time.sleep(10)


def changeDate(driver, bigData=True):
    # while True:
    # try:
    if bigData:
        click_button(
            driver, '//*[@id="Xa6NNY6v3"]/div[2]/div[2]/div/div[1]/div/div[1]/div[2]/div/div/div/div/input', 1)
        click_button(
            driver, '//*[@id="MhrHMIXeY"]/div[3]/div[2]/div/div/div[2]/div[2]/div[1]/p/strong')
        click_button(
            driver, '//*[@id="Xa6NNY6v3"]/div[2]/div[2]/div/div[2]/button')
    else:
        driver.execute_script("window.scrollTo(3, 200);")
        time.sleep(10)
        click_button(
            driver, '//*[@id="vGLSGXFn4"]/div[2]/div[2]/div/div[1]/div/div[1]/div[2]/div/div/div/div/input', 1)
        click_button(
            driver, '//*[@id="vGLSGXFn4"]/div[2]/div[2]/div/div[2]/button')

    driver.execute_script("window.scrollTo(3, 700);")
    return
    # except:
    # print('Change date is not working, trying again!')
    # time.sleep(3)


def generalClickerUsingHover(driver, hover_place_xpath: list, button_xpath: str, moreButtons: list):
    # Wait for the hover element to be present
    retry = 0
    done = False
    while not done and retry < 4:
        try:
            hoverElements = []
            for x in hover_place_xpath:
                hover_element = WebDriverWait(driver, 10).until(
                    EC.presence_of_element_located((By.XPATH, x))
                )
                hoverElements.append(hover_element)
            # Initialize ActionChains for the driver
            actions = ActionChains(driver)

            # Hover over the specified element
            for x in hoverElements:
                actions.move_to_element(x).perform()

            # Wait for the button to be visible after hovering
            button = WebDriverWait(driver, 10).until(
                EC.visibility_of_element_located((By.XPATH, button_xpath))
            )

            # Click the button
            button.click()

            for timeS, buttons in moreButtons:
                while True:
                    try:
                        time.sleep(timeS+5)
                        click_button(
                            driver,  buttons)

                        break
                    except KeyboardInterrupt:
                        print("\nKeyboardInterrupt caught! Exiting gracefully.")
                        exit()

                    except:
                        print(f'Button: {buttons} not found, trying again')
            done = True
        except KeyboardInterrupt:
            print("\nKeyboardInterrupt caught! Exiting gracefully.")
            exit()
        except Exception as e:
            retry += 1
            try:
                try:
                    xPathAnnoyingStuff = '//*[@id="Fp7r46_74"]/div[2]/div/div[4]/div/div[1]/div[2]/button[1]/font/font'
                    button = WebDriverWait(driver, 5).until(
                        EC.visibility_of_element_located(
                            (By.XPATH, xPathAnnoyingStuff))
                    )
                    button.click()
                except KeyboardInterrupt:
                    print("\nKeyboardInterrupt caught! Exiting gracefully.")
                    exit()
                except:
                    pass
                try:
                    xPathAnnoyingStuff = '//*[@id="jDYt9enkQ"]/div[2]/div/div[4]/div/div[1]/div[2]/button[1]/font/font'
                    button = WebDriverWait(driver, 5).until(
                        EC.visibility_of_element_located(
                            (By.XPATH, xPathAnnoyingStuff))
                    )
                    button.click()
                except KeyboardInterrupt:
                    print("\nKeyboardInterrupt caught! Exiting gracefully.")
                    exit()
                except:
                    pass
            except KeyboardInterrupt:
                print("\nKeyboardInterrupt caught! Exiting gracefully.")
                exit()
            except:
                print('Annoying button was not found, trying again')
    if done:
        return True
    else:
        return False


def downloadDailyOrders(driver):
    time.sleep(5)
    print('Started downloading Daily Orders')
    if SME:
        click_button(
            driver, '//*[@id="BinsPAkmk"]/div[2]/div[1]/div/div/ul/div[1]')
        id = 'jDYt9enkQ'
        one = 193-2
        one_two = 193
        two = 448
        two_two = 450
    else:
        click_button(
            driver, '//*[@id="BinsPAkmk"]/div[2]/div[1]/div/div/ul/div[2]')
        id = 'Fp7r46_74'
        one = 451-2
        one_two = 451
        two = 468-2
        two_two = 468
    time.sleep(5)

    result1 = generalClickerUsingHover(driver, [f'//*[@id="{id}"]/div[3]/div[2]',],
                                       f'//*[@id="{id}"]/div[2]/div/div[2]/div/div[1]/div/div/div/span',
                                       [(3, f'/html/body/div[{one}]/div[2]/div/div/div/div[2]/div[2]/div[1]/div[3]/div[3]/label/span/input'), (3, f'/html/body/div[{one}]/div[2]/div/div/div/div[3]/button[3]')])
    time.sleep(5)
    if not result1:
        one = one_two
        two = two_two
        result1 = generalClickerUsingHover(driver, [f'//*[@id="{id}"]/div[3]/div[2]',],
                                           f'//*[@id="{id}"]/div[2]/div/div[2]/div/div[1]/div/div/div/span',
                                           [(3, f'/html/body/div[{one}]/div[2]/div/div/div/div[2]/div[2]/div[1]/div[3]/div[3]/label/span/input'), (3, f'/html/body/div[{one}]/div[2]/div/div/div/div[3]/button[3]')])

    result2 = generalClickerUsingHover(driver, [f'//*[@id="{id}"]/div[3]/div[2]',],
                                       f'//*[@id="{id}"]/div[2]/div/span/div/div/a', [(3, f'/html/body/div[{one+1}]/ul/li[2]')])

    time.sleep(15)
    result3 = generalClickerUsingHover(driver, [f'//*[@id="{id}"]/div[3]/div[2]', f'//*[@id="{id}"]/div[2]/div/div[1]/div/div'],
                                       f'/html/body/div[{two}]/ul/li[1]', [(5, '/html/body/div[5]/div[2]/div/div/a/i')])

    time.sleep(3)
    print('Finished downloading Daily Orders')


def downloadExpMetric(driver):
    time.sleep(5)
    print('Started downloading Exp metric')
    driver.execute_script(f"window.scrollTo(3, {int(700*5.7)});")
    if SME:
        click_button(
            driver, '//*[@id="AYOTVDYju"]/div[2]/div[1]/div/div/ul/div[1]')
        id = 'vaCnXa-lF'
        one = 353-2
        one_two = 353
        two = 458-2
        two_two = 458
    else:
        click_button(
            driver, '//*[@id="AYOTVDYju"]/div[2]/div[1]/div/div/ul/div[2]')
        id = '8cZGuRrNt'
        one = 454-2
        one_two = 454
        two = 471-2
        two_two = 471

    time.sleep(5)
    result1 = generalClickerUsingHover(driver, [f'//*[@id="{id}"]/div[3]/div[2]',],
                                       f'//*[@id="{id}"]/div[2]/div/div[2]/div/div[1]/div/div/div/span',
                                       [(3, f'/html/body/div[{one}]/div[2]/div/div/div/div[2]/div[2]/div[1]/div[3]/div[3]/label/span/input'), (3, f'/html/body/div[{one}]/div[2]/div/div/div/div[3]/button[3]')])
    time.sleep(5)
    if not result1:
        one = one_two
        two = two_two
        result1 = generalClickerUsingHover(driver, [f'//*[@id="{id}"]/div[3]/div[2]',],
                                           f'//*[@id="{id}"]/div[2]/div/div[2]/div/div[1]/div/div/div/span',
                                           [(3, f'/html/body/div[{one}]/div[2]/div/div/div/div[2]/div[2]/div[1]/div[3]/div[3]/label/span/input'), (3, f'/html/body/div[{one}]/div[2]/div/div/div/div[3]/button[3]')])

    result2 = generalClickerUsingHover(driver, [f'//*[@id="{id}"]/div[3]/div[2]',],
                                       f'//*[@id="{id}"]/div[2]/div/span/div/div/a', [(3, f'/html/body/div[{one+1}]/ul/li[2]')])

    time.sleep(15)
    result3 = generalClickerUsingHover(driver, [f'//*[@id="{id}"]/div[3]/div[2]', f'//*[@id="{id}"]/div[2]/div/div[1]/div/div'],
                                       f'/html/body/div[{two}]/ul/li[1]', [(5, '/html/body/div[5]/div[2]/div/div/a/i')])

    time.sleep(3)
    print('Finished downloading Exp metric')


def downloadBurnMetrics(driver):
    time.sleep(5)
    print('Started downloading Burn Metrics')
    driver.execute_script(f"window.scrollTo(3, {int(700*6.8)});")
    if SME:
        click_button(
            driver, '//*[@id="RXUYBRryq"]/div[2]/div[1]/div/div/ul/div[1]')
        id = 'wpXbSv9qm'
        one = 373-2
        one_two = 373
        two = 459-2
        two_two = 459
    else:
        click_button(
            driver, '//*[@id="RXUYBRryq"]/div[2]/div[1]/div/div/ul/div[2]')
        id = '9wFx9T-hj'
        one = 476-2
        one_two = 476
        two = 493-2
        two_two = 493

    time.sleep(5)
    result1 = generalClickerUsingHover(driver, [f'//*[@id="{id}"]/div[3]/div[2]',],
                                       f'//*[@id="{id}"]/div[2]/div/div[2]/div/div[1]/div/div/div/span',
                                       [(3, f'/html/body/div[{one}]/div[2]/div/div/div/div[2]/div[2]/div[1]/div[3]/div[3]/label/span/input'), (3, f'/html/body/div[{one}]/div[2]/div/div/div/div[3]/button[3]')])
    time.sleep(5)
    if not result1:
        one = one_two
        two = two_two
        result1 = generalClickerUsingHover(driver, [f'//*[@id="{id}"]/div[3]/div[2]',],
                                           f'//*[@id="{id}"]/div[2]/div/div[2]/div/div[1]/div/div/div/span',
                                           [(3, f'/html/body/div[{one}]/div[2]/div/div/div/div[2]/div[2]/div[1]/div[3]/div[3]/label/span/input'), (3, f'/html/body/div[{one}]/div[2]/div/div/div/div[3]/button[3]')])

    result2 = generalClickerUsingHover(driver, [f'//*[@id="{id}"]/div[3]/div[2]',],
                                       f'//*[@id="{id}"]/div[2]/div/span/div/div/a', [(3, f'/html/body/div[{one+1}]/ul/li[2]')])

    time.sleep(15)
    result3 = generalClickerUsingHover(driver, [f'//*[@id="{id}"]/div[3]/div[2]', f'//*[@id="{id}"]/div[2]/div/div[1]/div/div'],
                                       f'/html/body/div[{two}]/ul/li[1]', [(5, '/html/body/div[5]/div[2]/div/div/a/i')])

    time.sleep(3)
    print('Finished downloading Burn Metrics')


def downloadAverageTickets(driver):
    time.sleep(5)
    print('Started downloading Average Tickets')
    driver.execute_script(f"window.scrollTo(3, {int(700*8.5)});")
    if SME:
        click_button(
            driver, '//*[@id="CjR1qoh7Q"]/div[2]/div[1]/div/div/ul/div[1]')
        id = 'WNr6uNgu3'
        one = 413-2
        one_two = 413
        two = 461-2
        two_two = 461
    else:
        click_button(
            driver, '//*[@id="CjR1qoh7Q"]/div[2]/div[1]/div/div/ul/div[2]')
        id = 'YupXR3f3V'
        one = 485-2
        one_two = 485
        two = 502-2
        two_two = 502
    time.sleep(5)
    result1 = generalClickerUsingHover(driver, [f'//*[@id="{id}"]/div[3]/div[2]',],
                                       f'//*[@id="{id}"]/div[2]/div/div[2]/div/div[1]/div/div/div/span',
                                       [(3, f'/html/body/div[{one}]/div[2]/div/div/div/div[2]/div[2]/div[1]/div[3]/div[3]/label/span/input'), (3, f'/html/body/div[{one}]/div[2]/div/div/div/div[3]/button[3]')])
    time.sleep(5)
    if not result1:
        one = one_two
        two = two_two
        result1 = generalClickerUsingHover(driver, [f'//*[@id="{id}"]/div[3]/div[2]',],
                                           f'//*[@id="{id}"]/div[2]/div/div[2]/div/div[1]/div/div/div/span',
                                           [(3, f'/html/body/div[{one}]/div[2]/div/div/div/div[2]/div[2]/div[1]/div[3]/div[3]/label/span/input'), (3, f'/html/body/div[{one}]/div[2]/div/div/div/div[3]/button[3]')])

    result2 = generalClickerUsingHover(driver, [f'//*[@id="{id}"]/div[3]/div[2]',],
                                       f'//*[@id="{id}"]/div[2]/div/span/div/div/a', [(3, f'/html/body/div[{one+1}]/ul/li[2]')])

    time.sleep(15)
    result3 = generalClickerUsingHover(driver, [f'//*[@id="{id}"]/div[3]/div[2]', f'//*[@id="{id}"]/div[2]/div/div[1]/div/div'],
                                       f'/html/body/div[{two}]/ul/li[1]', [(5, '/html/body/div[5]/div[2]/div/div/a/i')])

    time.sleep(3)
    print('Finished downloading Average Tickets')


def giveMeABreak():
    print('que vaina loca')
    while True:
        time.sleep(100)
        print('que vaina loca')


def body(driver):
    enterDiDiDashboard(driver)
    changeDate(driver)
    downloadDailyOrders(driver)
    downloadExpMetric(driver)
    downloadBurnMetrics(driver)
    downloadAverageTickets(driver)


def theWholeProcess():
    driver = start()
    body(driver)
    quit(driver)


SME = 1

if __name__ == "__main__":
    theWholeProcess()
    SME = 0
    time.sleep(60)
    theWholeProcess()

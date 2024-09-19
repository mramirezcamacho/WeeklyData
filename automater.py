import datetime
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.keys import Keys
from selenium.common.exceptions import NoSuchElementException, ElementClickInterceptedException, StaleElementReferenceException
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


def start():
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
    driver.get("https://bigdata.intra.didiglobal.com/analysis_platform_static/board.html#/?type=reportView&reportId=80601&source=market&showMetric=false&subReportId=162327")
    return driver


def quit(driver):
    driver.quit()


def check_element(driver, xpath):
    try:
        driver.find_element("xpath", xpath)
        return True
    except NoSuchElementException:
        return False


def writeInBox(driver, input_xpath, textToInsert):
    while True:
        try:
            # Locate the input field using the provided XPath
            date_input = driver.find_element("xpath", input_xpath)

            # Clear the input field and enter the text
            date_input.clear()  # Clears any pre-existing value in the input
            date_input.send_keys(textToInsert)

            # Exit the loop if the input was successfully found and text inserted
            break

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
        button.click()
        if deleteStuff:
            pushKey(driver, button_xpath, [Keys.CONTROL, "a"])
            pushKey(driver, button_xpath, [Keys.BACKSPACE])
            button.send_keys(getDates())
    except NoSuchElementException:
        print(f"Button with XPath {button_xpath} not found.")
    except ElementClickInterceptedException:
        print(f"""Button with XPath {
              button_xpath} could not be clicked (intercepted).""")


def checkCredentials(driver, file_path='credentials.txt'):
    result = read_first_two_lines(file_path)

    if result is None:
        print("File not found.")
    else:
        first_line, second_line = result
        writeInBox(driver, '//*[@id="username"]', first_line)
        writeInBox(driver, '//*[@id="password"]', second_line)
        click_button(driver, '//*[@id="submit"]')
    return


def is_page_loading(driver):
    return driver.execute_script("return document.readyState") != "complete"


def enterDiDiDashboard(driver):
    # XPath for the submit button
    time.sleep(10)
    checkCredentials(driver)
    xpath = '//*[@id="submit"]'
    while check_element(driver, xpath) and 'https://me.didiglobal.com/project/stargate-auth/html/login.html' in driver.current_url:
        print("Logging in...")
        time.sleep(5)
    target_url = 'https://bigdata.intra.didiglobal.com/analysis_platform_static/board.html#/?type=reportView&reportId=80601&source=market&showMetric=false&subReportId=162327'
    while driver.current_url != target_url:
        print("URL is different, waiting...")
        time.sleep(5)

    while is_page_loading(driver):
        print("Page is still loading...")
        time.sleep(1)  # Sleep for a short time to avoid overloading the loop
    time.sleep(10)


def changeDate(driver):
    click_button(
        driver, '//*[@id="Xa6NNY6v3"]/div[2]/div[2]/div/div[1]/div/div[1]/div[2]/div/div/div/div/input', 1)
    click_button(
        driver, '//*[@id="MhrHMIXeY"]/div[3]/div[2]/div/div/div[2]/div[2]/div[1]/p/strong')
    click_button(
        driver, '//*[@id="Xa6NNY6v3"]/div[2]/div[2]/div/div[2]/button')
    driver.execute_script("window.scrollTo(0, 700);")


def generalClickerUsingHover(driver, hover_place_xpath: list, button_xpath: str, moreButtons: list):
    # Wait for the hover element to be present
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
            try:
                time.sleep(timeS)
                click_button(
                    driver,  buttons)
            except:
                time.sleep(timeS)
                click_button(
                    driver,  buttons)
    except Exception as e:
        print(f"Error: {e}")


def setFiltersCityName(driver, hover_place_xpath: list, button_xpath):
    # Wait for the hover element to be present
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
        time.sleep(2)
        click_button(
            driver,  '/html/body/div[193]/div[2]/div/div/div/div[2]/div[2]/div[1]/div[3]/div[3]/label/span/input')
        time.sleep(5)
        click_button(
            driver, '/html/body/div[193]/div[2]/div/div/div/div[3]/button[3]')

    except Exception as e:
        print(f"Error: {e}")


def setFiltersWeek(driver, hover_place_xpath: list, button_xpath):
    # Wait for the hover element to be present
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
        time.sleep(5)
        click_button(
            driver, '/html/body/div[194]/ul/li[2]')
        time.sleep(10)

    except Exception as e:
        print(f"Error: {e}")


def downloadData(driver, hover_place_xpath: list, button_xpath):
    # Wait for the hover element to be present
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

        time.sleep(12)

        click_button(driver, '/html/body/div[7]/div[2]/div/div/a/i')

    except Exception as e:
        print(f"Error: {e}")


def downloadDailyOrders(driver):
    generalClickerUsingHover(driver, ['//*[@id="jDYt9enkQ"]/div[3]/div[2]/div/div[1]/div[2]/div[5]/div[1]/div[4]/div[1]/canvas',],
                             '//*[@id="jDYt9enkQ"]/div[2]/div/div[2]/div/div[1]/div/div/div/span',
                             [(2, '/html/body/div[193]/div[2]/div/div/div/div[2]/div[2]/div[1]/div[3]/div[3]/label/span/input'), (5, '/html/body/div[193]/div[2]/div/div/div/div[3]/button[3]')])
    time.sleep(5)
    generalClickerUsingHover(driver, ['//*[@id="jDYt9enkQ"]/div[3]/div[2]/div/div[1]/div[2]/div[5]/div[1]/div[4]/div[1]/canvas',],
                             '//*[@id="jDYt9enkQ"]/div[2]/div/span/div/div/a', [(5, '/html/body/div[194]/ul/li[2]')])

    time.sleep(15)
    generalClickerUsingHover(driver, ['//*[@id="jDYt9enkQ"]/div[3]/div[2]/div/div[1]/div[2]/div[5]/div[1]/div[4]/div[1]/canvas', '//*[@id="jDYt9enkQ"]/div[2]/div/div[1]/div/div'],
                             '/html/body/div[450]/ul/li[1]', [(12, '/html/body/div[7]/div[2]/div/div/a/i')])


def body(driver):
    enterDiDiDashboard(driver)
    changeDate(driver)
    time.sleep(5)
    downloadDailyOrders(driver)
    time.sleep(100)


if __name__ == "__main__":
    driver = start()
    body(driver)
    quit(driver)
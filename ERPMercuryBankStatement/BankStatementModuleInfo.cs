using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;

namespace ERPMercuryBankStatement
{
    class BankStatementModuleClassInfo : UniXP.Common.CModuleClassInfo
    {
        public BankStatementModuleClassInfo()
        {
             UniXP.Common.CLASSINFO objClassInfo;

             objClassInfo = new UniXP.Common.CLASSINFO();
             objClassInfo.enClassType = UniXP.Common.EnumClassType.mcView;
             objClassInfo.strClassName = "ERPMercuryBankStatement.BankStatementEditor";
             objClassInfo.strName = "Банковские выписки";
             objClassInfo.strDescription = "Банковские выписки";
             objClassInfo.lID = 0;
             objClassInfo.nImage = 1;
             objClassInfo.strResourceName = "IMAGES_MONEYSMALL";
             m_arClassInfo.Add(objClassInfo);

             objClassInfo = new UniXP.Common.CLASSINFO() 
             { 
                 enClassType = UniXP.Common.EnumClassType.mcView, 
                 strClassName = "ERPMercuryBankStatement.EarningEditor", 
                 strName = "Платежи (форма 1)", 
                 strDescription = "Модуль для регистрации платежей по форме оплаты №1", 
                 lID = 1, nImage = 1, strResourceName = "IMAGES_MONEYSMALL" 
             };
             m_arClassInfo.Add(objClassInfo);

            objClassInfo = new UniXP.Common.CLASSINFO()
             {
                 enClassType = UniXP.Common.EnumClassType.mcView,
                 strClassName = "ERPMercuryBankStatement.CEarningEditor",
                 strName = "Платежи (форма 2)",
                 strDescription = "Модуль для регистрации платежей по форме оплаты №2",
                 lID = 2,
                 nImage = 1,
                 strResourceName = "IMAGES_MONEYSMALL"
             };
            m_arClassInfo.Add(objClassInfo);

            objClassInfo = new UniXP.Common.CLASSINFO()
            {
                enClassType = UniXP.Common.EnumClassType.mcView,
                strClassName = "ERPMercuryBankStatement.CustomerInitialDebtPaymentType_1_Editor",
                strName = "Начальная задолженность (форма 1)",
                strDescription = "Модуль для регистрации начальной задолженности клиента по форме оплаты №1",
                lID = 3,
                nImage = 1,
                strResourceName = "IMAGES_MONEYSMALL"
            };
            m_arClassInfo.Add(objClassInfo);

            objClassInfo = new UniXP.Common.CLASSINFO()
            {
                enClassType = UniXP.Common.EnumClassType.mcView,
                strClassName = "ERPMercuryBankStatement.CustomerInitialDebtPaymentType_2_Editor",
                strName = "Начальная задолженность (форма 2)",
                strDescription = "Модуль для регистрации начальной задолженности клиента по форме оплаты №2",
                lID = 4,
                nImage = 1,
                strResourceName = "IMAGES_MONEYSMALL"
            };
            m_arClassInfo.Add(objClassInfo);
        }
    }

    public class CBankStatementModuleInfo : UniXP.Common.CClientModuleInfo
    {
        public CBankStatementModuleInfo()
            : base(Assembly.GetExecutingAssembly(),
                UniXP.Common.EnumDLLType.typeItem,
                new System.Guid("{E199C052-EA96-4BE2-B953-BBEABAC2CCD9}"),
                new System.Guid("{A6319AD0-08C0-49ED-B25B-659BAB622B15}"),
                ERPMercuryBankStatement.Properties.Resources.IMAGES_MONEYSMALL,
                ERPMercuryBankStatement.Properties.Resources.IMAGES_MONEYSMALL)
        {
        }

        /// <summary>
        /// Выполняет операции по проверке правильности установки модуля в системе.
        /// </summary>
        /// <param name="objProfile">Профиль пользователя.</param>
        public override System.Boolean Check(UniXP.Common.CProfile objProfile)
        {
            return true;
        }
        /// <summary>
        /// Выполняет операции по удалению модуля из системы.
        /// </summary>
        /// <param name="objProfile">Профиль пользователя.</param>
        public override System.Boolean UnInstall(UniXP.Common.CProfile objProfile)
        {
            return true;
        }
        /// <summary>
        /// Производит действия по обновлению при установке новой версии подключаемого модуля.
        /// </summary>
        /// <param name="objProfile">Профиль пользователя.</param>
        public override System.Boolean Update(UniXP.Common.CProfile objProfile)
        {
            return true;
        }
        /// <summary>
        /// Возвращает список доступных классов в данном модуле.
        /// </summary>
        public override UniXP.Common.CModuleClassInfo GetClassInfo()
        {
            return new BankStatementModuleClassInfo();
        }

        /// <summary>
        /// Выполняет операции по установке модуля в систему.
        /// </summary>
        /// <param name="objProfile">Профиль пользователя.</param>
        public override bool Install(UniXP.Common.CProfile objProfile)
        {
            return true;
        }
    }

    public class ModuleInfo : PlugIn.IModuleInfo
    {
        public UniXP.Common.CClientModuleInfo GetModuleInfo()
        {
            return new CBankStatementModuleInfo();
        }
    }
}

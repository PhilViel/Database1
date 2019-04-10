/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	psCONV_RapportLettreDeSolde
Description         :	Rapport pour la lettre des solde d'Epargne, subvention et rENDement.
Valeurs de retours  :	Dataset de données

Note                :	
					2013-06-25	Donald Huppé	    Création :  GLPI 9403
					2013-10-09	Donald Huppé	    Ajout du champ BenefRegimeIndividuel
					2013-10-24	Donald Huppé	    Ajout des conventions IND non fermée
					2013-10-30	Donald Huppé	    Ajout de SubscriberID dans @PlanClassification
					2014-01-13	Donald Huppé	    Ajout de SplitGrants pour ajustement du rapport SSRS
					2014-01-06	Donald Huppé	    GLPI 10853 : Ne pas afficher les Conventions concours (SaleSourceID = 50) signées en 2013 et +
					2014-01-21	Donald Huppé	    suite de GLPI 10853 : prévoir que u.SaleSourceID peut être NULL
					2014-01-24	Donald Huppé	    Exclure les IND dont tous les soldes sont = 0
					2014-01-27	Donald Huppé	    ON met la note 1 pour les convention IND qui commencent par I ou F
					2014-01-28	Donald Huppé	    Pour les IND, ON prEND seulement les unités en état EPG et CPT
					2014-01-29	Donald Huppé	    Bilinguiser le nom des Plans
					2014-02-06	Donald Huppé	    Ne plus inscrire 0 pour les rENDement négatif, ON le gère maintenant dans le rapport. 
												    Vu qu'on additionne les 2 rENDements, avant de le mettre à 0
					2014-02-10	Donald Huppé	    Changer la lcause where du startDate dans les état de groupe d'unité et de la convention (gain de performance dans certaines situations
												    ON fait : startDate < DATEADD(d,1 ,@dtDateTo)
												    plutôt que : LEFT(CONVERT(VARCHAR, startDate, 120), 10) <= @dtDateTo
					2014-03-20	Donald Huppé	    Exclure les conventions du glpi 11113
					2014-09-15	Donald Huppé	    glpi 12400
					2015-03-31	Donald Huppé	    correction de : ON met la note 1 pour les convention IND qui commencent par I ou F
												    C'est I ou F (j'avais codé E au lieu de F)
					2018-04-17	Donald Huppé	    jira PROD-7726 : Pour les convention IND, sortir les convention qui ont des solde d'épargne ou de subvention. au lieu de sortir les convention en EPG et CPT
												    Ajout des champs : ConventionStateID, Immobilise, GagnantConcours, EducaidePersevera
					2018-06-22	Donald Huppé	    jira prod-10332 : Afficher les conv quui ont seulement des frais de souscription
                    2018-07-13  Pierre-Luc Simard   Ajout des valeurs pour les PAE
                    2018-07-26  Steeve Picard       Correction du «bEstAdmissiblePAE» selon l'âge du bénéficiaire dans le cas d'une convention de plan de type «IND»
                    2018-08-07  Pierre-Luc Simard   Ajout de l'admissibilité des cas de devancement pour les convention Individuel et admissiblité à 16 ans inclusivement
                    2018-07-10  Pierre-Luc Simard   Ne plus compter les unités en proposition
					2018-11-12	Maxime Martel		Retourner le regroupement regime pour l'affichage conditionnel dans le rapport
                    2018-12-20  Steeve Picard       Retourner aussi les conventions ayant seulement de la quote-part
                    2018-12-20  steeve Picard       Retourner les rendements négatifs

exec psCONV_RapportLettreDeSolde 667511, '2013-09-13'
exec psCONV_RapportLettreDeSolde 575993, '2018-06-15'
exec psCONV_RapportLettreDeSolde 394077, '2018-04-16'
exec psCONV_RapportLettreDeSolde 154641, '2017-03-29'
exec psCONV_RapportLettreDeSolde 200263, '2017-03-29'
exec psCONV_RapportLettreDeSolde 779990, '2017-03-29'
exec psCONV_RapportLettreDeSolde 679786, '2017-10-18'
exec psCONV_RapportLettreDeSolde 606191, '2017-10-18'

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettreDeSolde] (
	@SubscriberID int,
	@dtDateTo DATETIME -- Date de fin de l'intervalle des opérations
	)
AS
BEGIN

    SET ARITHABORT ON -- patch sinon ON ne peut pas faire un refresh du dataset dans le rapport SSRS

	DECLARE @today DATETIME
	DECLARE @PlanClassification VARCHAR(500)
	
	SET @today = GETDATE()
    SELECT @PlanClassification = dbo.fnCONV_ObtenirDossierClient(@SubscriberID, 1) + '\RELEVES_DEPOTS\' + REPLACE(LEFT(CONVERT(VARCHAR, @dtDateTo, 120), 10), '-', '') + '_ra_sold_' + CAST(@SubscriberID AS VARCHAR(15)) + '_' + REPLACE(LEFT(CONVERT(VARCHAR, @today, 120), 10), '-', '');

	SELECT ConventionID 
	INTO #ListeConvGLPI11113 
	FROM dbo.Un_Convention 
	WHERE ConventionNo IN (
	--Liste 1
	'T-20081101088',	'T-20081101113',	'T-20081101126', /* à checker*/	'T-20090501027',	'T-20090501041',	'T-20090501101',	'T-20091101151',	'T-20091101247',	'T-20100127001',	'T-20100501024',	'T-20100501231',	'T-20100501243',	'T-20100501265',	'T-20100501279',	'T-20100915011',	'T-20100915042',
	'T-20100915066',	'T-20100915068',	'T-20101101020',	'T-20101101039',	'T-20101101044',	'T-20101101045',	'T-20101101073',	'T-20101101182',	'T-20101101201',	'T-20101101206',	'T-20101101242',	'T-20101101246',	'T-20101101273',	'T-20101101298',	'T-20101201001',	'T-20110304001',
	 -- liste 2
	'F-19991119001',	'F-20000516020',	'F-20000516030',	'F-20011113001',	'F-20011214012',	'F-2026850',	'F-2098503',	'F-2159727',	'I-20020927003',	'I-20021003001',	'I-20021224003',	'I-20030321001',	'I-20030603001',	'I-20030603002',	'I-20031010002',	'I-20031216001',	'I-20041221001',	'I-20050106001',	'I-20051115001',
	'I-20051201002',	'I-20070329001',	'I-20070504002',	'I-20070711001',	'I-20071018001',	'I-20071205001',	'I-20071218002',	'I-20080523001',	'I-20080729001',	'I-20080818001',	'I-20080925001',	'I-20081009001',	'I-20081022004',	'I-20081125001',	'I-20081204002',	'I-20090218001',	'I-20090313001',	'I-20090429001',
	'I-20090708001',	'I-20090910003',	'I-20091008001',	'I-20091105001',	'I-20091111002',	'I-20091127003',	'I-20091218001',	'I-20091222002',	'I-20091222003',	'I-20091223002',	'I-20091223006',	'I-20091223008',	'I-20100527001',	'I-20100729001',	'I-20100923001',	'I-20100928001',	'I-20101006001',	'I-20101015001',	'I-20101022003',
	'I-20101026001',	'I-20101110002',	'I-20101115003',	'I-20101116001',	'I-20101118002',	'I-20101118003',	'I-20101119002',	'I-20101124001',	'I-20101126001',	'I-20101126003',	'I-20101126004',	'I-20101126005',	'I-20101202001',	'I-20101202007',	'I-20101209001',	'I-20101209002',	'I-20101209003',	'I-20101209007',	'I-20101210002',
	'I-20101216003',	'I-20101216007',	'I-20101216012',	'I-20101216013',	'I-20101217003',	'I-20101217004',	'I-20101220001',	'I-20101220002',	'I-20101222001',	'I-20101222003',	'I-20101222006',	'I-20101222008',	'I-20101223012',	'I-20110105001',	'I-20110429001',	'I-20110602001',	'I-20110628002',	'I-20110801001',	'I-20110811006',	'I-20110823005',
	'I-20110823006',	'I-20110916001',	'I-20110928008',	'I-20110928057',	'I-20110929002',	'I-20110929015',	'I-20110929025',	'I-20110929077',	'I-20110929093',	'I-20110930001',	'I-20111005001',	'I-20111010001',	'I-20111025001',	'I-20111026004',	'I-20111027001',	'I-20111101002',	'I-20111103001',	'I-20111108002',	'I-20111111001',	'I-20111114001',	'I-20111114005',
	'I-20111114007',	'I-20111118005',	'I-20111121003',	'I-20111122002',	'I-20111124007',	'I-20111124008',	'I-20111124009',	'I-20111128002',	'I-20111128004',	'I-20111128005',	'I-20111128006',	'I-20111128007',	'I-20111128008',	'I-20111128009',	'I-20111128010',	'I-20111128011',	'I-20111129001',	'I-20111129002',	'I-20111129006',	'I-20111201001',	'I-20111202001',
	'I-20111202002',	'I-20111207001',	'I-20111207002',	'I-20111207003',	'I-20111207011',	'I-20111208001',	'I-20111208002',	'I-20111214003',	'I-20111215004',	'I-20111215005',	'I-20111216001',	'I-20111219010',	'I-20111219038',	'I-20111220004',	'I-20111221001',	'I-20111221005',	'I-20111221008',	'I-20111221009',	'I-20111221011',
	'I-20111221014',	'I-20111221015',	'I-20111221019',	'I-20111221020',	'I-20111221022',	'I-20111221023',	'I-20120104002',	'I-20120105006',	'I-20120105007',	'I-20120312030',	'I-20120312033',	'I-20120412003',	'I-20120507001',	'I-20120803001',	'I-20120810007',	'I-20121012009',	'I-20121012010',	'I-20121116001',	'I-20121116002',	'I-20121123002',	'I-20121127002',
	'I-20121218002',	'I-20130121001',	'I-20130201012',	'I-20130403001',	'I-20130403002',	'I-20130517004',	'I-20130723007',	'I-20130723012',	'I-20130723024',	'I-20130816006',	'I-20131004014',	'I-20131112067',	'I-20131112086',	'I-20131115016',	'I-20140221010',
	--liste 3
	'F-20000516020',	'F-20000516030',	'F-20011113001',	'F-20011214012',	'F-2026850',	'F-2098503',	'F-2159727',	'I-20020927003',	'I-20021003001',	'I-20021224003',	'I-20030321001',	'I-20030603001',	'I-20030603002',	'I-20031010002',	'I-20031216001',	'I-20041221001',	'I-20050106001',	'I-20051115001',	'I-20051201002',	'I-20070329001',
	'I-20070504002',	'I-20071018001',	'I-20071205001',	'I-20071218002',	'I-20080729001',	'I-20080925001',	'I-20081009001',	'I-20081022004',	'I-20081125001',	'I-20081204002',	'I-20090218001',	'I-20090313001',	'I-20090708001',	'I-20090910003',	'I-20091008001',	'I-20091105001',	'I-20091111002',
	'I-20091127003',	'I-20091222002',	'I-20091222003',	'I-20091223002',	'I-20091223006',	'I-20091223008',	'I-20100527001',	'I-20100923001',	'I-20100928001',	'I-20101006001',	'I-20101015001',	'I-20101022003',	'I-20101026001',
	'I-20101110002',	'I-20101115003',	'I-20101116001',	'I-20101118002',	'I-20101118003',	'I-20101119002',	'I-20101124001',	'I-20101126001',	'I-20101126003',	'I-20101126004',	'I-20101126005',	'I-20101202001',	'I-20101202007',	'I-20101209002',	'I-20101209003',	'I-20101209007',	'I-20101210002',	'I-20101216003',	'I-20101216007',	'I-20101216012',
	'I-20101217003',	'I-20101217004',	'I-20101220002',	'I-20101222001',	'I-20101222003',	'I-20101222006',	'I-20101223012',	'I-20110105001',	'I-20110429001',	'I-20110602001',	'I-20110916001',	'I-20110929077',	'I-20110930001',	'I-20111025001',	'I-20111027001',	'I-20111101002',	'I-20111103001',	'I-20111114007',	'I-20111121003',	'I-20111122002',	'I-20111124007',
	'I-20111124008',	'I-20111124009',	'I-20111128004',	'I-20111128005',	'I-20111128006',	'I-20111128007',	'I-20111128009',	'I-20111128010',	'I-20111129001',	'I-20111129006',	'I-20111201001',	'I-20111202001',	'I-20111202002',	'I-20111207001',	'I-20111207002',	'I-20111207003',	'I-20111207011',	'I-20111208001',	'I-20111208002',	'I-20111214003',	'I-20111215004',
	'I-20111215005',	'I-20111216001',	'I-20111219038',	'I-20111220004',	'I-20111221001',	'I-20111221005',	'I-20111221008',	'I-20111221011',	'I-20111221014',	'I-20111221015',	'I-20111221019',	'I-20111221020',	'I-20111221022',	'I-20111221023',	'I-20120105006',	'I-20120105007',	'I-20120507001',	'I-20120803001',	'I-20120810007',	'I-20121218002',
	-- liste 4
	'T-20100107001',	'T-20100107002',	'T-20100107003',	'T-20100107004',	'T-20100107005',	'T-20100107006',	'T-20100107007',	'T-20100107009',	'T-20100107010',	'T-20100107011',	'T-20100111002',	'T-20100111003',	'T-20100111006',	'T-20100111009',	'T-20100111010',	'T-20100111012',	'T-20100111015',	'T-20100111016',	'T-20100111017',	'T-20100111018',	'T-20100111020',	'T-20100111021',
	'T-20100111022',	'T-20100112001',	'T-20100112002',	'T-20100316001',	'T-20100316003',	'T-20100522002',	'T-20100522007',	'T-20100522009',	'T-20100522012',	'T-20100522014',	'T-20100522016',	'T-20100522021',	'T-20100522027',	'T-20100522030',	'T-20100522031',	'T-20100522032',	'T-20100522033',	'T-20100522036',	'T-20100522039',	'T-20100522042',	'T-20100522043',	'T-20100522044',	'T-20100522046',
	'T-20100830003',	'T-20100928001',	'T-20100928002',	'T-20100928003',	'T-20100928004',	'T-20100928005',	'T-20100928006',	'T-20100928007',	'T-20100928008',	'T-20100928009',	'T-20100928011',	'T-20100928012',	'T-20101125004',	'T-20101125006',	'T-20101125009',	'T-20101125010',	'T-20101125013',	'T-20101125014',	'T-20101125017',	'T-20101125018',	'T-20101125019',	'T-20101125021',
	'T-20101125022',	'T-20101125023',	'T-20101125025',	'T-20101125026',	'T-20101125027',	'T-20101125033',	'T-20101125034',	'T-20101125037',	'T-20101125041',	'T-20101125044',	'T-20101125045',	'T-20101125046',	'T-20110118001',	'T-20110118005',	'T-20110118006',	'T-20110118008',	'T-20110118010',	'T-20110118011',	'T-20110127001',	'T-20110318001',	'T-20110318002',	'T-20110526002',	'T-20110705002',
	'T-20110705003',	'T-20110705004',	'T-20110705005',	'T-20110705006',	'T-20110705007',	'T-20110705008',	'T-20110705009',	'T-20110705011',	'T-20110705012',	'T-20110705013',	'T-20110705014',	'T-20110705015',	'T-20110705016',	'T-20110705017',	'T-20110705018',	'T-20110705019',	'T-20110705022',	'T-20110705025',	'T-20110705026',	'T-20110705027',	'T-20110705028',	'T-20110705029',
	'T-20110705031',	'T-20110705032',	'T-20110705033',	'T-20110705034',	'T-20110705035',	'T-20110705036',	'T-20110705038',	'T-20110705039',	'T-20110705040',	'T-20110705042',	'T-20110705043',	'T-20110705044',	'T-20110705045',	'T-20110705046',	'T-20110705047',	'T-20110705048',	'T-20110705049',	'T-20110705050',	'T-20110705051',	'T-20110705052',	'T-20110705053',	'T-20110705054',	'T-20110705056',
	'T-20110705058',	'T-20110705059',	'T-20110705060',	'T-20110705061',	'T-20110705062',	'T-20110705063',	'T-20110705065',	'T-20110705068',	'T-20110705070',	'T-20110705071',	'T-20110705072',	'T-20110705073',	'T-20110705074',	'T-20110705075',	'T-20110705077',	'T-20110705078',	'T-20110705079',	'T-20110705081',	'T-20110705082',	'T-20110705083',	'T-20110705084',	'T-20110705087',	'T-20110705088',
	'T-20110705089',	'T-20110705090',	'T-20110705091',	'T-20110705092',	'T-20110705093',	'T-20110705094',	'T-20110705095',	'T-20110705096',	'T-20110705097',	'T-20110705098',	'T-20110705099',	'T-20110705100',	'T-20110829001',	'T-20110920001',	'T-20110922001',	'T-20110922002',	'T-20110922003',	'T-20110922004',	'T-20110922005',	'T-20110922007',	'T-20111123001',	'T-20111123002',	'T-20111123003',	'T-20111123005',
	'T-20111123010',	'T-20111123012',	'T-20111123013',	'T-20111123015',	'T-20111123016',	'T-20111123023',	'T-20111123027',	'T-20111123028',	'T-20111123031',	'T-20111123032',	'T-20111123045',	'T-20111123050',	'T-20111123053',	'T-20111123059',	'T-20111123060',	'T-20111123063',	'T-20111123064',	'T-20111123065',	'T-20111123067',	'T-20111123068',	'T-20111123069',	'T-20111123070',	'T-20111123072',	'T-20111123076',	'T-20111123077',
	'T-20111123079',	'T-20111123080',	'T-20111123081',	'T-20111123082',	'T-20111123083',	'T-20111123084',	'T-20111123085',	'T-20111123086',	'T-20111123087',	'T-20111123088',	'T-20111123089',	'T-20111123091',	'T-20111123092',	'T-20111123093',	'T-20111123094',	'T-20111123095',	'T-20111123097',	'T-20111123098',	'T-20111123099',	'T-20111123100',	'T-20111123101',	'T-20111123103',	'T-20111123105',
	'T-20111123106',	'T-20111123107',	'T-20111123108',	'T-20111123109',	'T-20111123112',	'T-20111123113',	'T-20111123115',	'T-20111123116',	'T-20111123117',	'T-20111123118',	'T-20111123119',	'T-20111123121',	'T-20111123122',	'T-20111123123',	'T-20111123125',	'T-20111123126',	'T-20111123127',	'T-20111123128',	'T-20111123129',	'T-20111123132',	'T-20111123134',	'T-20111123135',	'T-20111123138',	'T-20111123139',
	'T-20111123140',	'T-20111123141',	'T-20111123142',	'T-20111123143',	'T-20111123145',	'T-20111123146',	'T-20111123148',	'T-20111123150',	'T-20111123151',	'T-20111123154',	'T-20111123155',	'T-20111123156',	'T-20111123157',	'T-20111123158',	'T-20111123160',	'T-20111123161',	'T-20111123162',	'T-20111123163',	'T-20111123165',	'T-20111123169',	'T-20111123170',	'T-20111123171',	'T-20111123173',	'T-20111123176',	'T-20111123177',
	'T-20111123178',	'T-20111123179',	'T-20111123180',	'T-20111123181',	'T-20111123182',	'T-20111123184',	'T-20111123188',	'T-20111123190',	'T-20111220001',	'T-20111220002',	'T-20111220004',	'T-20111220005',	'T-20111220006',	'T-20111220007',	'T-20111220008',	'T-20111220011',	'T-20111220019',	'T-20111220020',	'T-20111220021',	'T-20111220022',	'T-20111220024',	'T-20111220026',	'T-20111220027',	'T-20111220028',	'T-20111220030',
	'T-20111220031',	'T-20111220032',	'T-20111220033',	'T-20111220034',	'T-20111220037',	'T-20111220038',	'T-20111220039',	'T-20111220041',	'T-20111220042',	'T-20111220044',	'T-20111220045',	'T-20111220046',	'T-20111220048',	'T-20111220049',	'T-20111220050',	'T-20120117001',	'T-20120117003',	'T-20120117004',	'T-20120117006',	'T-20120117008',	'T-20120117009',	'T-20120117011',	'T-20120117012',
	'T-20120117014',	'T-20120117015',	'T-20120117019',	'T-20120117020',	'T-20120301001',	'T-20120301002',	'T-20120301003',	'T-20120301004',	'T-20120301006',	'T-20120301007',	'T-20120301009',	'T-20120301010',	'T-20120301011',	'T-20120301012',	'T-20120301013',	'T-20120301014',	'T-20120301015',	'T-20120301017',	'T-20120301020',	'T-20120301021',	'T-20120301022',	'T-20120301023',	'T-20120301024',
	'T-20120301026',	'T-20120301030',	'T-20120301037',	'T-20120427001',	'T-20120524001',	'T-20120524002',	'T-20120530001',	'T-20120530013',	'T-20120530014',	'T-20120530015',	'T-20120530016',	'T-20120530018',	'T-20120530019',	'T-20120530020',	'T-20120901001',	'T-20120901002',	'T-20121020002',	'T-20121020006',	'T-20121020008',	'T-20121020009',	'T-20121020010',	'T-20121020011',	'T-20121024001',	'T-20121108001',	'T-20121126001',
	'T-20121126002',	'T-20121126003',	'T-20121126004',	'T-20121126005',	'T-20121126006',	'T-20121126008',	'T-20121126009',	'T-20121126010',	'T-20121126011',	'T-20121126013',	'T-20121126015',	'T-20121126016',	'T-20121126017',	'T-20121126018',	'T-20121126019',	'T-20121126020',	'T-20121126021',	'T-20121126023',	'T-20121126024',	'T-20121126025',	'T-20130114001',	'T-20130114002',	'T-20130114006',
	'T-20130126001',	'T-20130126002',	'T-20130226001',	'T-20130321001',	'T-20130321002',	'T-20130321003',	'T-20130326001',	'T-20130415001',	'T-20130415016',	'T-20130415017',	'T-20130415018',	'T-20130415019',	'T-20130415022',	'T-20130415025',	'T-20130415028',	'T-20130415029',	'T-20130415030',	'T-20130415033',	'T-20130415034',	'T-20130415035',	'T-20130429001',	'T-20130529002',	'T-20130529003',	'T-20130529010',	'T-20130529017',	'T-20130529020',
	'T-20130529022',	'T-20130529026',	'T-20130529028',	'T-20130529029',	'T-20130529032',	'T-20130529034',	'T-20130529035',	'T-20130529037',	'T-20130529039',	'T-20130617001',	'T-20130729001',	'T-20130909001',	'T-20130909007',	'T-20130909008',	'T-20130923001',	'T-20130923004',
	-- liste 5
	'T-20100111004',	'T-20100111007',	'T-20100111008',	'T-20100111011',	'T-20100111013',	'T-20100111014',	'T-20100111019',	'T-20100311007',	'T-20100316002',	'T-20100317001',	'T-20100522001',	'T-20100522003',	'T-20100522005',	'T-20100522006',	'T-20100522008',	'T-20100522010',	'T-20100522011',	'T-20100522013',	'T-20100522015',	'T-20100522017',	'T-20100522018',	'T-20100522019',	'T-20100522020',	'T-20100522022',	'T-20100522024',
	'T-20100522025',	'T-20100522028',	'T-20100522029',	'T-20100522034',	'T-20100522035',	'T-20100522037',	'T-20100522038',	'T-20100522040',	'T-20100522041',	'T-20100522045',	'T-20100522047',	'T-20100830001',	'T-20100830002',	'T-20100830004',	'T-20100830005',	'T-20100830006',	'T-20100830007',	'T-20100830008',	'T-20100830009',	'T-20100928010',	'T-20101125002',	'T-20101125003',	'T-20101125005',	'T-20101125007',	'T-20101125011',	'T-20101125016',
	'T-20101125020',	'T-20101125030',	'T-20101125031',	'T-20101125032',	'T-20101125035',	'T-20101125036',	'T-20101125038',	'T-20101125039',	'T-20101125040',	'T-20101125042',	'T-20101125043',	'T-20110118002',	'T-20110118003',	'T-20110118004',	'T-20110118007',	'T-20110118009',	'T-20110318003',	'T-20110318004',	'T-20110705010',	'T-20110705020',	'T-20110705021',	'T-20110705023',	'T-20110705024',	'T-20110705037',	'T-20110705041',	'T-20110705055',
	'T-20110705064',	'T-20110705069',	'T-20110705080',	'T-20110705085',	'T-20110922006',	'T-20111123004',	'T-20111123006',	'T-20111123008',	'T-20111123009',	'T-20111123011',	'T-20111123014',	'T-20111123017',	'T-20111123018',	'T-20111123019',	'T-20111123020',	'T-20111123021',	'T-20111123022',	'T-20111123024',	'T-20111123025',	'T-20111123026',	'T-20111123029',	'T-20111123030',	'T-20111123033',	'T-20111123034',	'T-20111123035',	'T-20111123037',	'T-20111123038',	'T-20111123039',
	'T-20111123040',	'T-20111123041',	'T-20111123042',	'T-20111123044',	'T-20111123046',	'T-20111123047',	'T-20111123048',	'T-20111123049',	'T-20111123051',	'T-20111123052',	'T-20111123054',	'T-20111123055',	'T-20111123056',	'T-20111123057',	'T-20111123058',	'T-20111123061',	'T-20111123062',	'T-20111123066',	'T-20111123071',	'T-20111123073',	'T-20111123074',	'T-20111123075',	'T-20111123078',	'T-20111123090',	'T-20111123096',	'T-20111123102',	'T-20111123110',
	'T-20111123111',	'T-20111123114',	'T-20111123120',	'T-20111123124',	'T-20111123130',	'T-20111123131',	'T-20111123137',	'T-20111123144',	'T-20111123147',	'T-20111123149',	'T-20111123159',	'T-20111123166',	'T-20111123172',	'T-20111123175',	'T-20111123185',	'T-20111220009',	'T-20111220010',	'T-20111220012',	'T-20111220013',	'T-20111220014',	'T-20111220015',	'T-20111220016',	'T-20111220017',	'T-20111220018',	'T-20111220023',	'T-20111220025',	'T-20111220029',
	'T-20111220036',	'T-20111220040',	'T-20111220047',	'T-20111220051',	'T-20111220052',	'T-20120117002',	'T-20120117005',	'T-20120117007',	'T-20120117010',	'T-20120117013',	'T-20120117016',	'T-20120117017',	'T-20120216001',	'T-20120301005',	'T-20120301008',	'T-20120301016',	'T-20120301018',	'T-20120301019',	'T-20120301025',	'T-20120301027',	'T-20120301032',	'T-20120301033',	'T-20120301034',	'T-20120530002',	'T-20120530003',
	'T-20120530004',	'T-20120530005',	'T-20120530006',	'T-20120530008',	'T-20120530009',	'T-20120530011',	'T-20120530012',	'T-20120530017',	'T-20120901003',	'T-20120915767',	'T-20121020001',	'T-20121020003',	'T-20121020004',	'T-20121020005',	'T-20121020007',	'T-20121020012',	'T-20121126007',	'T-20121126012',	'T-20121126014',	'T-20130114003',	'T-20130114005',	'T-20130114007',	'T-20130114008',	'T-20130114009',	'T-20130114010',	'T-20130415002',	'T-20130415003',
	'T-20130415004',	'T-20130415005',	'T-20130415006',	'T-20130415007',	'T-20130415009',	'T-20130415010',	'T-20130415012',	'T-20130415013',	'T-20130415014',	'T-20130415015',	'T-20130415020',	'T-20130415021',	'T-20130415023',	'T-20130415024',	'T-20130415026',	'T-20130415027',	'T-20130415032',	'T-20130529001',	'T-20130529004',	'T-20130529005',	'T-20130529006',	'T-20130529007',	'T-20130529008',	'T-20130529009',	'T-20130529011',	'T-20130529012',	'T-20130529013',	'T-20130529014',
	'T-20130529015',	'T-20130529016',	'T-20130529018',	'T-20130529019',	'T-20130529024',	'T-20130529025',	'T-20130529027',	'T-20130529031',	'T-20130529033',	'T-20130529036',	'T-20130529038',	'T-20130529040',	'T-20130529041',	'T-20130529042',	'T-20130529043',	'T-20130701001',	'T-20130909002',	'T-20130909003',	'T-20130909004',	'T-20130909005',	'T-20130909006',	'T-20130923002',	'T-20130923003'	
	)

	SELECT 
		HS.LangID,
		SEX.LongSexName,
		SEX.ShortSexName,
		C.SubscriberID,
		SubsPrenom = HS.FirstName,
		SubsNom = HS.LastName,
		SubsAdr = a.Address,
		SubsVille = a.City,
		SubsCodePostal = dbo.fn_Mo_FormatZIP( a.ZipCode,a.countryID),
		SubsProvince = a.StateName,
		C.BeneficiaryID,
		BenPrenom = HB.FirstName,
		BenNom = HB.LastName,
        BenAge = dbo.fn_Mo_Age(HB.BirthDate, @dtDateTo),
		C.conventionno,
        C.ConventionID,
        C.YearQualif,
		P.PlanID,
		P.OrderOfPlanInReport,
		PlanDesc =  CASE 
				        WHEN HS.LangID = 'ENU' AND P.PlanDesc = 'Reeeflex' THEN 'Reflex'
				        WHEN HS.LangID = 'ENU' AND P.PlanDesc = 'Individuel' THEN 'Individual'
				    ELSE P.PlanDesc
				    END,
        P.iID_Regroupement_Regime,
		QteUniteConv,

		Epargne = ISNULL(Epargne,0),
		Frais = ISNULL(CT.Frais,0),

		SCEE = ISNULL(SCEE,0),
        SCEEPlus = ISNULL(SCEEPlus,0),
		BEC = ISNULL(BEC,0),
		IQEEBase = ISNULL(IQEEBase,0),
        IQEEMajore = ISNULL(IQEEMajore,0),

		RENDEpargne = ISNULL(RENDInd,0),

		RENDIncitatif = ISNULL(INS,0) + ISNULL(IST,0) + ISNULL(ISPlus,0) + ISNULL(IBC,0) +  ISNULL(ICQ,0) + ISNULL(MIM,0) + ISNULL(IQI,0) +  ISNULL(III,0) + ISNULL(IIQ,0) + ISNULL(IMQ,0),

		Note1 = CASE WHEN p.PlanTypeID = 'IND' and SUBSTRING(C.conventionno,1,1) IN ('I','F') /*and riO.iID_Convention_Destination is null*/ THEN 1 ELSE 0 END,
		PlanClassification = @PlanClassification,
		P.PlanTypeID,
		ConventionStateID,
		Immobilise  = CASE WHEN C.tiMaximisationREEE = 2 THEN 1 ELSE 0 END,
		GagnantConcours = CASE WHEN GC.ConventionID IS NOT NULL THEN 1 ELSE 0 END,
		EducaidePersevera = CASE WHEN Persevera.ConventionID IS NOT NULL THEN 1 ELSE 0 END,
        B.bDevancement_AdmissibilitePAE
	INTO #table1
	FROM dbo.Un_Convention C
	JOIN Un_Plan P ON C.PlanID = P.PlanID 
    JOIN Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
    JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
	JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
	JOIN dbo.Mo_Adr A ON A.AdrID = HS.AdrID
	JOIN Mo_Sex SEX ON SEX.SexID = HS.SexID AND SEX.LangID = HS.LangID
	JOIN (
		-- LES CONVENTIONS COLLECTIVES 
		SELECT
			U2.ConventionID,
			QteUniteConv = SUM(U2.UnitQty + ISNULL(UR.QteRes,0))
		FROM dbo.Un_Convention C2
		--join (
		--	select C3.ConventionID ,DateRIEstimé = min(	dbo.FN_UN_EstimatedIntReimbDate (PmtByYearID,PmtQty,BenefAgeOnBegining,InForceDate,IntReimbAge,IntReimbDateAdjust))
		--	FROM dbo.Un_Convention c3
		--	JOIN dbo.Un_Unit u ON C3.ConventionID = u.ConventionID
		--	JOIN Un_Modal m ON u.ModalID = m.ModalID
		--	JOIN Un_Plan p ON C3.PlanID = p.PlanID and p.PlanID <> 4 
		--	where C3.SubscriberID = @SubscriberID
		--	group by C3.ConventionID
		--	HAVING min(	dbo.FN_UN_EstimatedIntReimbDate (PmtByYearID,PmtQty,BenefAgeOnBegining,InForceDate,IntReimbAge,IntReimbDateAdjust)) >= '2014-09-15'
		--	)ri ON ri.ConventionID = C2.ConventionID
        --join (
		--	select 
		--		CS.conventionid ,
		--		CCS.startdate,
		--		CS.ConventionStateID
		--	from 
		--		un_conventionconventionstate cs
		--		join (
		--			select 
		--			conventionid,
		--			startdate = max(startDate)
		--			from un_conventionconventionstate
		--			where startDate < DATEADD(d,1 ,@dtDateTo)
		--			--where LEFT(CONVERT(VARCHAR, startDate, 120), 10) <= @dtDateTo -- Si je veux l'état à une date précise 
		--			group by conventionid
		--			) ccs ON CCS.conventionid = CS.conventionid 
		--				and CCS.startdate = CS.startdate 
		--				and CS.ConventionStateID <> 'FRM' -- je veux les convention qui ont cet état
		--	) css ON C2.conventionid = CSS.conventionid
        JOIN Un_Plan P2 ON C2.PlanID = P2.PlanID AND P2.PlanTypeID = 'COL'
		JOIN dbo.Un_Unit U2 ON C2.ConventionID = U2.ConventionID
        LEFT JOIN (
            SELECT 
				UR1.UnitID, QteRes =SUM(UR1.UnitQty) 
			FROM Un_UnitReduction UR1
			JOIN dbo.Un_Unit U1 ON UR1.UnitID = U1.UnitID
			JOIN dbo.Un_Convention C1 ON U1.ConventionID = C1.ConventionID
			WHERE C1.SubscriberID = @SubscriberID
				AND ReductionDate > @dtDateTo 
			GROUP BY UR1.UnitID
			) UR ON U2.UnitID = UR.UnitID
		WHERE C2.SubscriberID = @SubscriberID
            AND ISNULL(U2.ActivationConnectID, 0) <> 0
        GROUP BY U2.ConventionID
			
		UNION ALL
			
		-- LES CONVENTIONS INDIVIDUELLES 
		SELECT
			U3.ConventionID,
			QteUniteConv = SUM(U3.UnitQty + ISNULL(UR.QteRes,0))
		FROM dbo.Un_Convention C3
		JOIN Un_Plan P3 ON C3.PlanID = P3.PlanID AND P3.PlanTypeID = 'IND'
		JOIN dbo.Un_Unit U3 ON C3.ConventionID = U3.ConventionID
		--JOIN (
		--	select 
		--		uS.unitid,
		--		uuS.startdate,
		--		uS.UnitStateID
		--	from 
		--		Un_UnitunitState us
		--		join (
		--			select 
		--			unitid,
		--			startdate = max(startDate)
		--			from un_unitunitstate
		--			where startDate < DATEADD(d,1 ,@dtDateTo)
		--			--where LEFT(CONVERT(VARCHAR, startDate, 120), 10) <= @dtDateTo
		--			group by unitid
		--			) uus ON uuS.unitid = uS.unitid 
		--				and uuS.startdate = uS.startdate 
		--				--and uS.UnitStateID in ('EPG','CPT')
		--	) uss ON U3.UnitID = usS.UnitID
		--join (
		--	select 
		--		CS.conventionid ,
		--		CCS.startdate,
		--		CS.ConventionStateID
		--	from 
		--		un_conventionconventionstate cs
		--		join (
		--			select 
		--			conventionid,
		--			startdate = max(startDate)
		--			from un_conventionconventionstate
		--			where startDate < DATEADD(d,1 ,@dtDateTo)
		--			--where LEFT(CONVERT(VARCHAR, startDate, 120), 10) <= @dtDateTo -- Si je veux l'état à une date précise 
		--			group by conventionid
		--			) ccs ON CCS.conventionid = CS.conventionid 
		--				and CCS.startdate = CS.startdate 
		--				and CS.ConventionStateID <> 'FRM' -- je veux les convention qui ont cet état
		--	) css ON C3.conventionid = CSS.conventionid
		LEFT JOIN (
            SELECT 
		        UR1.UnitID, 
                QteRes = SUM(UR1.UnitQty) 
		    FROM Un_UnitReduction UR1
			JOIN dbo.Un_Unit U1 ON UR1.UnitID = U1.UnitID
			JOIN dbo.Un_Convention C1 ON U1.ConventionID = C1.ConventionID
			WHERE C1.SubscriberID = @SubscriberID
				AND ReductionDate > @dtDateTo 
			GROUP BY UR1.UnitID
			) UR ON U3.UnitID = UR.UnitID
		WHERE C3.SubscriberID = @SubscriberID
            AND ISNULL(U3.ActivationConnectID, 0) <> 0
        GROUP BY U3.ConventionID			
		) QU ON C.ConventionID = QU.ConventionID
	JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(@dtDateTo, NULL) CSS ON CSS.ConventionID = C.ConventionID
    /*JOIN (
		SELECT
			CS.conventionid,
			CCS.startdate,
			CS.ConventionStateID
		FROM un_conventionconventionstate cs
	    JOIN (
			SELECT 
			    conventionid,
			    startdate = max(startDate)
			FROM un_conventionconventionstate
			WHERE startDate < DATEADD(d,1 ,@dtDateTo)
			--where LEFT(CONVERT(VARCHAR, startDate, 120), 10) <= @dtDateTo -- Si je veux l'état à une date précise 
			GROUP BY conventionid
			) CCS ON CCS.conventionid = CS.conventionid 
				AND CCS.startdate = CS.startdate 
				AND CS.ConventionStateID <> 'FRM' -- je veux les convention qui ont cet état
		) CSS ON C.conventionid = CSS.conventionid*/
	LEFT JOIN (
		SELECT
			U3.ConventionID
		FROM dbo.Un_Convention C3
	    JOIN dbo.Un_Unit U3 ON C3.ConventionID = U3.ConventionID
		WHERE C3.SubscriberID = @SubscriberID
			AND U3.SaleSourceID = 50
			AND ISNULL(U3.TerminatedDate, '9999-12-31') > @dtDateTo
		GROUP BY U3.ConventionID
		) GC ON GC.ConventionID = C.conventionid
	LEFT JOIN (
		SELECT U3.ConventionID
		FROM dbo.Un_Convention C3
		JOIN dbo.Un_Unit U3 ON C3.ConventionID = U3.ConventionID
		WHERE C3.SubscriberID = @SubscriberID
			AND U3.SaleSourceID IN (
					92,--	SUP-CEN-Centraide
					221,--	SUP-ECE-Éducaide Centraide Estrie
					222,--	SUP-ECS-Éducaide Centraide Côte-Sud
					235--	SUP-EPP-Éducaide Programme Persevera				
				)
			AND ISNULL(U3.TerminatedDate,'9999-12-31') > @dtDateTo
		GROUP BY U3.ConventionID
		) Persevera ON Persevera.ConventionID = C.ConventionID
	/*
	LEFT JOIN (
		SELECT DISTINCT C.ConventionID
		FROM tblCONV_Pret p
		JOIN tblCONV_PretDetail pd ON pd.iID_Pret = p.iID_Pret
		JOIN tblCONV_PretEncaissementCreancier pec ON peC.iID_PretEncaissementCreancier = pd.iID_PretEncaissementCreancier
		JOIN Un_Oper o ON O.OperID = pd.OperID
		JOIN Un_Cotisation ct ON CT.OperID = O.OperID
		JOIN Un_Unit u ON u.UnitID = CT.UnitID
		JOIN Un_Convention c ON C.ConventionID = u.ConventionID
		WHERE 
			p.SubscriberID = @SubscriberID
		)IMMO ON IMMO.ConventionID = C.ConventionID
	*/
	LEFT JOIN (
		SELECT
			U.ConventionID,
			Epargne = SUM(CT.Cotisation),
			Frais = SUM(CT.Fee)
		FROM dbo.Un_Convention C
		JOIN dbo.Un_Unit U ON C.ConventionID = U.ConventionID
		JOIN Un_Cotisation Ct  ON CT.UnitID = U.UnitID
		WHERE C.SubscriberID = @SubscriberID
			AND CT.EffectDate <= @dtDateTo
		GROUP BY U.ConventionID
		) CT ON C.ConventionID = CT.conventionid
	LEFT JOIN (
		SELECT
			U1.ConventionID,
			DateDernierRIN = MAX(o1.OperDate)
		FROM dbo.Un_Convention c1
		JOIN dbo.Un_Unit U1 ON C1.ConventionID = U1.ConventionID
		JOIN Un_Cotisation Ct1  ON CT1.UnitID = U1.UnitID
		JOIN Un_Oper o1 ON o1.OperID = cT1.OperID
		LEFT JOIN Un_OperCancelation OC1 ON o1.OperID = OC1.OperSourceID
		LEFT JOIN Un_OperCancelation OC2 ON o1.OperID = OC2.OperID
		WHERE C1.SubscriberID = @SubscriberID
			AND o1.OperDate <= @dtDateTo
			AND o1.OperTypeID = 'RIN'
			AND OC1.OperSourceID IS NULL
			AND OC2.OperID IS NULL
		GROUP BY U1.ConventionID
		) RIN ON RIN.ConventionID = C.conventionid
	LEFT JOIN (
		SELECT 
            C2.ConventionID,
			DateDernierPAE = MAX(O2.OperDate)
		FROM dbo.Un_Convention C2
		JOIN un_scholarship S2 ON S2.ConventionID = C2.ConventionID
		JOIN Un_ScholarshipPmt SP2 ON S2.ScholarshipID = SP2.ScholarshipID
		JOIN Un_Oper O2 ON SP2.OperID = O2.OperID
		LEFT JOIN Un_OperCancelation OC1 ON O2.OperID = OC1.OperSourceID
		LEFT JOIN Un_OperCancelation OC2 ON O2.OperID = OC2.OperID
		WHERE C2.SubscriberID = @SubscriberID
			AND O2.OperDate <= @dtDateTo
			AND OC1.OperSourceID is null
			AND OC2.OperID is null
		GROUP BY C2.ConventionID
		) PAE ON PAE.ConventionID = C.ConventionID
	LEFT JOIN (
		SELECT 
			C.ConventionID,			
			IQEEBase = SUM(CASE WHEN CO.conventionopertypeid = 'CBQ' THEN ConventionOperAmount ELSE 0 END),
			IQEEMajore = SUM(CASE WHEN CO.conventionopertypeid = 'MMQ' THEN ConventionOperAmount ELSE 0 END),
			RENDInd = SUM(CASE WHEN CO.conventionopertypeid IN ( 'INM','ITR') THEN ConventionOperAmount ELSE 0 END),
			IBC = SUM(CASE WHEN CO.conventionopertypeid = 'IBC' THEN ConventionOperAmount ELSE 0 END),
			ICQ = SUM(CASE WHEN CO.conventionopertypeid = 'ICQ' THEN ConventionOperAmount ELSE 0 END),
			III = SUM(CASE WHEN CO.conventionopertypeid = 'III' THEN ConventionOperAmount ELSE 0 END),
			IIQ = SUM(CASE WHEN CO.conventionopertypeid = 'IIQ' THEN ConventionOperAmount ELSE 0 END),
			IMQ = SUM(CASE WHEN CO.conventionopertypeid = 'IMQ' THEN ConventionOperAmount ELSE 0 END),
			MIM = SUM(CASE WHEN CO.conventionopertypeid = 'MIM' THEN ConventionOperAmount ELSE 0 END),
			IQI = SUM(CASE WHEN CO.conventionopertypeid = 'IQI' THEN ConventionOperAmount ELSE 0 END),
			INS = SUM(CASE WHEN CO.conventionopertypeid = 'INS' THEN ConventionOperAmount ELSE 0 END),
			ISPlus = SUM(CASE WHEN CO.conventionopertypeid = 'IS+' THEN ConventionOperAmount ELSE 0 END),
			IST = SUM(CASE WHEN CO.conventionopertypeid = 'IST' THEN ConventionOperAmount ELSE 0 END),
			RENDementTotal = SUM(CASE WHEN CO.conventionopertypeid IN ( 'IBC','ICQ','III','IIQ','IMQ','INS','IS+','IST','INM','ITR','MIM','IQI') THEN ConventionOperAmount ELSE 0 END )
		FROM Un_ConventionOper CO
		JOIN dbo.Un_Convention C ON CO.ConventionID = C.ConventionID
		JOIN Un_Oper O ON CO.OperID = O.OperID
		JOIN Un_Plan P ON C.PlanID = P.PlanID
		WHERE C.SubscriberID = @SubscriberID
			AND O.operdate <= @dtDateTo
			AND CO.conventionopertypeid IN('CBQ','MMQ','IBC','ICQ','III','IIQ','IMQ','INS','IS+','IST','INM','ITR','MIM','IQI')
		GROUP BY C.ConventionID
		) V ON C.ConventionID = V.ConventionID
	LEFT JOIN (
		SELECT 
			CE.conventionid,
			SCEE = SUM(fcesg),
			SCEEPlus = SUM(facesg),
			BEC = SUM(fCLB)
		FROM un_cesp CE
		JOIN dbo.Un_Convention C ON CE.conventionid = C.conventionid
		JOIN Un_Plan P ON C.PlanID = P.PlanID
		JOIN un_oper OP ON CE.operid = OP.operid
		WHERE C.SubscriberID = @SubscriberID
			AND OP.operdate <= @dtDateTo
		GROUP BY CE.conventionid
		) scee ON C.conventionid = scee.conventionid
	--left JOIN (
	--	select r.iID_Convention_Destination
	--	from tblOPER_OperationsRIO r
	--	where r.bRIO_Annulee = 0 and r.bRIO_QuiAnnule = 0
	--	group BY r.iID_Convention_Destination
	--		) rio ON C.ConventionID = riO.iID_Convention_Destination 
	LEFT JOIN (
		SELECT 
			C.ConventionID,			
			SoldeRENDementApresPAE =    CASE 
							                WHEN PAE.LastPAEOperID is not null 
                                            THEN SUM(   CASE 
                                                            WHEN CO.conventionopertypeid IN ( 'IBC','ICQ','III','IIQ','IMQ','INS','IS+','IST','INM','ITR','MIM','IQI') 
                                                            THEN ConventionOperAmount ELSE 0 
                                                        END)
							                ELSE 999999999
							            END
		FROM Un_ConventionOper co
		JOIN dbo.Un_Convention C ON CO.ConventionID = C.ConventionID
		JOIN Un_Oper o ON CO.OperID = O.OperID
		JOIN Un_Plan P ON C.PlanID = P.PlanID
		LEFT JOIN (
			SELECT 
                C.ConventionID, 
                LastPAEOperID = MAX(O.OperID)
			FROM dbo.Un_Convention C
			JOIN un_scholarship S ON S.ConventionID = C.ConventionID
			JOIN Un_ScholarshipPmt SP ON S.ScholarshipID = SP.ScholarshipID
			JOIN Un_Oper O ON SP.OperID = O.OperID
			LEFT JOIN Un_OperCancelation OC1 ON O.OperID = OC1.OperSourceID
			LEFT JOIN Un_OperCancelation OC2 ON O.OperID = OC2.OperID
			WHERE C.SubscriberID = @SubscriberID
				AND O.operdate <= @dtDateTo
				AND C.PlanID = 4
				AND OC1.OperSourceID IS NULL
				AND OC2.OperID IS NULL
			GROUP by C.ConventionID
			) PAE ON PAE.ConventionID = CO.ConventionID
		WHERE C.PlanID = 4
			AND C.SubscriberID = @SubscriberID
			AND O.operdate <= @dtDateTo
			AND O.OperID <= ISNULL(PAE.LastPAEOperID,0)
		    --and O.operdate <= @dtDateTo
			AND CO.conventionopertypeid in('IBC','ICQ','III','IIQ','IMQ','INS','IS+','IST','INM','ITR','MIM','IQI')
		GROUP BY 
            C.ConventionID,
            PAE.LastPAEOperID
		) SoldeRENDementApresPAE ON C.ConventionID = SoldeRENDementApresPAE.ConventionID
	WHERE C.SubscriberID = @SubscriberID
        AND CSS.ConventionStateID <> 'FRM'
		AND C.ConventionID NOT IN (SELECT ConventionID FROM #ListeConvGLPI11113)
	ORDER BY C.conventionno
		
	SELECT 
        LangID,
		LongSexName,
		ShortSexName,
		SubscriberID,
		SubsPrenom,
		SubsNom,
		SubsAdr,
		SubsVille,
		SubsCodePostal,
		SubsProvince,
		T1.BeneficiaryID,
		BenPrenom,
		BenNom,
        T1.BenAge,
		T1.conventionno,
		PlanID,
		OrderOfPlanInReport,
		PlanDesc,
        QteUniteConv,

		Epargne,
		Frais,

		SCEE = SCEE + SCEEPlus,
		BEC,
		IQEE = IQEEBase + IQEEMajore,

		RENDEpargne,
		RENDIncitatif,

		Note1,
		PlanClassification,
		
		PlanTypeID,
		BenefRegimeIndividuel = CASE WHEN T2.BeneficiaryID IS NOT NULL THEN 1 ELSE 0 END,
		SplitGrants = CASE WHEN RENDEpargneTotal > 0 OR T2.BeneficiaryID is not null THEN 1 ELSE 0 END,
		ConventionStateID,
		Immobilise,
		GagnantConcours,
		EducaidePersevera,
        bEstAdmissiblePAE = CASE WHEN PAE.ConventionID IS NOT NULL THEN 1 
                                 WHEN T1.PlanID = 4 AND T1.BenAge >= 16 THEN 1
                                 WHEN T1.PlanID = 4 AND ISNULL(bDevancement_AdmissibilitePAE, 0) = 1 THEN 1
                            ELSE 0 END, 
        mQuotepart = CASE WHEN PAE.ConventionID IS NOT NULL THEN PAE.QuotePart + PAE.RistourneAss ELSE QteUniteConv * RC.mRevenu_CohorteParUnite END,
        dDate_EffectiveValeurCohorte = ISNULL(RC.dDate_Effective, GETDATE()),      
        RC.mRevenus_Cohorte,
        RC.mQuantite_Unite,
        RC.mRevenu_CohorteParUnite,
		T1.iID_Regroupement_Regime
	FROM #table1 T1
	LEFT JOIN (
		SELECT DISTINCT BeneficiaryID 
		FROM #table1 T3
		WHERE PlanTypeID = 'IND'
        ) T2 ON T2.BeneficiaryID = T1.BeneficiaryID
	LEFT JOIN (
		SELECT
			BeneficiaryID,
			RENDEpargneTotal = SUM(RENDEpargne)
		FROM #table1
		GROUP BY BeneficiaryID
		) RE ON T1.BeneficiaryID = RE.BeneficiaryID	
    -- Valeur des revenus la cohorte
    LEFT JOIN dbo.fntCONV_ObtenirRevenusCohorte(GETDATE()) RC 
                            ON RC.iID_Regroupement_Regime = T1.iID_Regroupement_Regime
                                AND (RC.YearQualif = T1.YearQualif
                                    -- Si année de qualif est > que le max prévu, ON prEND le max
                                    OR (T1.YearQualif > RC.iDerniere_AnneeQualif AND RC.YearQualif = RC.iDerniere_AnneeQualif) 
                                    -- Si année de qualif est < que le min prévu, ON prEND le min
                                    OR (T1.YearQualif < RC.iPremiere_AnneeQualif AND RC.YearQualif = RC.iPremiere_AnneeQualif)
                                    )
    -- Valeur des PAE lorsque la convention est admissible
    LEFT JOIN dbo.fntCONV_ObtenirValeursPAECollectifDisponible(NULL) PAE ON PAE.ConventionID = T1.ConventionID
    WHERE 0=0
		AND (
			-- IL RESTE DU CAPITAL 
			   Epargne> 0
			OR Frais > 0 -- 2018-06-22
			OR SCEE > 0
			OR SCEEPlus > 0
			OR BEC > 0
			OR IQEEBase > 0
			OR IQEEMajore > 0
			OR RENDEpargne + RENDIncitatif > 0
            OR ISNULL(CASE WHEN PAE.ConventionID IS NOT NULL THEN PAE.QuotePart + PAE.RistourneAss ELSE QteUniteConv * RC.mRevenu_CohorteParUnite END, 0) > 0
			)
		-- ... AUCUN SOLDE NÉGATIF
		AND NOT (
			   Epargne < 0
			OR Frais < 0
			OR SCEE < 0
			OR SCEEPlus < 0
			OR BEC < 0
			OR IQEEBase < 0
			OR IQEEMajore < 0					
			--OR RENDEpargne + RENDIncitatif < 0
            OR ISNULL(CASE WHEN PAE.ConventionID IS NOT NULL THEN PAE.QuotePart + PAE.RistourneAss ELSE QteUniteConv * RC.mRevenu_CohorteParUnite END, 0) < 0
				)

		/*
	where
		-- Si c'est un régime IND, il faut qu'un des soldes soit différent de 0
		
		(
			(PlanTypeID = 'IND' and (Epargne <> 0 or Frais<>0 or SCEE <>0 or BEC<>0 or IQEE<>0  or (RENDEpargne + RENDIncitatif) > 0) )
			OR
			PlanTypeID <> 'IND'
		)
		*/
	
    SET ARITHABORT OFF
	
END

